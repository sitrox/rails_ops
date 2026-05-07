class RailsOps::Operation
  include RailsOps::Mixins::Policies
  include RailsOps::Mixins::SubOps
  include RailsOps::Mixins::SchemaValidation
  include RailsOps::Mixins::Authorization
  include RailsOps::Mixins::ParamAuthorization
  include RailsOps::Mixins::RequireContext
  include RailsOps::Mixins::LogSettings

  WHITELISTED_BASE_CLASSES_FOR_PARAM_INSPECTION = [
    ActiveRecord::Base,
    String,
    Integer,
    Symbol
  ].freeze

  # Tracks which call sites have already emitted the deprecation warning
  # for {with_rollback_on_exception}. Keyed by `"<path>:<lineno>"` so the
  # warning fires at most once per call location across the process,
  # avoiding log spam in long-running servers and per-request hot paths.
  WITH_ROLLBACK_DEPRECATION_SEEN = Concurrent::Map.new

  attr_reader :params
  attr_reader :context

  def self.run!(*args)
    new(*args).run!
  end

  def self.run(*args)
    new(*args).run
  end

  # Constructs a new operation instance with the given (optional) context and
  # the given (optional) params. This is the only way of assigning context and
  # params to an operation.
  #
  # If no context is provided, an empty context will be created.
  #
  # Note that, if provided, `params` must be a `Hash`. Other types such as
  # `ActiveSupport::HashWithIndifferentAccess` or `ActionController::Parameters`
  # are not supported.
  #
  # @param context [RailsOps::Context] Optional context
  # @param params [Hash] Optional parameters hash
  def initialize(context_or_params = {}, params = {})
    # Handle parameter signature
    case context_or_params
    when RailsOps::Context
      context = context_or_params
    when Hash, ActionController::Parameters
      context = nil
      params = context_or_params
    end

    @performed = false
    @context = context || RailsOps::Context.new

    # Convert ActionController::Parameters to a regular hash as we want to
    # bypass Rails' strong parameters for operation use.
    if defined?(ActionController::Parameters) && params.is_a?(ActionController::Parameters)
      params = params.permit!.to_h
    end

    # Remove web-specific param entries (such as `authenticity_token`)
    @params = params.to_h.with_indifferent_access.except(
      *ActionController::ParamsWrapper::EXCLUDE_PARAMETERS
    )

    # Validate params
    if _op_schema && !_skip_op_schema_validation
      validate_op_schema!
    end

    run_policies :on_init
  end

  def validate_op_schema!
    @params = _op_schema.validate!(params).with_indifferent_access
  end

  # Returns an array of exception classes that are considered as validation
  # errors.
  def validation_errors
    [RailsOps::Exceptions::ValidationFailed, ActiveRecord::RecordInvalid]
  end

  # Returns a copy of the operation's params, wrapped in an OpenStruct object.
  def osparams
    # rubocop: disable Style/OpenStructUse
    @osparams ||= OpenStruct.new(params)
    # rubocop: enable Style/OpenStructUse
  end

  # Return a hash of parameters with all sensitive data replaced.
  def filtered_params
    if defined?(ActiveSupport::ParameterFilter)
      # Rails >= 6
      cls = ActiveSupport::ParameterFilter
    else
      # Rails < 6
      cls = ActionDispatch::Http::ParameterFilter
    end

    f = cls.new(Rails.application.config.filter_parameters)
    return f.filter(params)
  end

  # Runs the operation using {run!} but rescues certain exceptions. Returns
  # `true` on success, otherwise `false`.
  #
  # If a database transaction is already open when {run} is called, the call
  # to {run!} is wrapped in a savepoint via
  # `ActiveRecord::Base.transaction(requires_new: true)`. This ensures that
  # any database writes performed by the operation are rolled back if a
  # validation error is raised, even though that error is then caught here
  # and converted into a `false` return value. This eliminates the most
  # common reason for using {with_rollback_on_exception}.
  #
  # When no transaction is open, behavior is identical to calling {run!}
  # directly: the caller is responsible for atomicity.
  def run
    if ActiveRecord::Base.connection.transaction_open?
      ActiveRecord::Base.transaction(requires_new: true) do
        run!
      end
    else
      run!
    end

    return true
  rescue *validation_errors
    return false
  end

  # Runs the operation. This internally calls the {perform} method and can only
  # be called once per operation instance. This is a bang method that raises at
  # any validation exception.
  def run!
    ActiveSupport::Notifications.instrument('run.rails_ops', operation: self) do
      ::RailsOps::Profiler.profile(object_id) do
        fail 'An operation can only be performed once.' if performed?
        @performed = true
        run_policies :before_perform
        perform
        run_policies :after_perform
      end
    end

    trigger :after_run, after_run_trigger_params

    return self
  end

  # Returns the contents of the operation as a nicely formatted string.
  def inspect
    inspection = self.class.name || '(AnonymousOp)'
    if params
      begin
        inspected_params = inspect_params(filtered_params)
      rescue StandardError
        inspected_params = '<could not inspect params>'
      end
      inspection += " (#{inspected_params})"
    end
    return inspection
  end

  # Determines if the operation has been performed yet.
  def performed?
    @performed
  end

  # Fails with an exception if the operation has not been performed yet.
  def check_performed!
    fail 'Operation has not yet been performed.' unless performed?
  end

  protected

  # This method actually performs the operation's logic and is called by {run}
  # or {run!}. Never call this method directly. Overwrite this method for
  # supplying operation logic.
  def perform
    fail NotImplementedError
  end

  # Determines a basic set of parameters that will be passed to the `after_run`
  # event. This is empty per default and is meant to overridden by superclasses
  # where necessary.
  def after_run_trigger_params
    {}
  end

  # Triggers an event of the given name using the given params using the
  # {RailsOps::Hookup} functionality. Any potential operation called by this
  # trigger will receive an operation context based on the context of the
  # current operation, but with an updated `op_chain` and with the `params`
  # supplied.
  #
  # @param [string] event The event name to trigger
  # @param [hash] params The params to provide to any ops called by this trigger
  def trigger(event, params = nil)
    if RailsOps.config.trigger_hookups_without_authorization
      without_authorization do
        RailsOps.hookup.trigger(self, event, params)
      end
    else
      RailsOps.hookup.trigger(self, event, params)
    end
  end

  # Yields the given block and rethrows any possible `StandardError` as a
  # {RailsOps::Exceptions::RollbackRequired} exception.
  #
  # @deprecated Since 1.8.0, validation errors raised inside {run} no
  #   longer leak partial database writes: {run} wraps the call to
  #   {run!} in a SAVEPOINT whenever an outer transaction is open, so
  #   any prior `model.save!` is rolled back automatically before
  #   {run} returns `false`. This helper is therefore obsolete for
  #   the common "save then do more work" pattern and will be
  #   removed in RailsOps 2.0.
  #
  #   To convert a non-validation `StandardError` into a rollback
  #   signal that escapes {run}'s rescue, raise
  #   {RailsOps::Exceptions::RollbackRequired} directly, e.g.
  #   `fail RailsOps::Exceptions::RollbackRequired, e, e.backtrace`.
  #
  #   Originally introduced for issue #28535.
  def with_rollback_on_exception(&_block)
    location = caller_locations(1, 1)&.first
    location_key = location && "#{location.path}:#{location.lineno}"
    if location_key.nil? || WITH_ROLLBACK_DEPRECATION_SEEN.put_if_absent(location_key, true).nil?
      RailsOps.deprecator.warn(
        '`with_rollback_on_exception` is deprecated and will be removed ' \
        'in RailsOps 2.0. Validation errors raised inside `run` are now ' \
        'rolled back automatically via a SAVEPOINT, so this helper is no ' \
        'longer required for the common "save then do more work" pattern. ' \
        'For non-validation errors that should trigger a rollback, raise ' \
        '`RailsOps::Exceptions::RollbackRequired` directly.',
        caller_locations(1)
      )
    end
    yield
  rescue StandardError => e
    fail RailsOps::Exceptions::RollbackRequired, e, e.backtrace
  end

  # Returns the contents of the params as a nicely formatted string.
  def inspect_params(params)
    params.each do |key, value|
      if value.is_a?(Hash)
        inspect_params(value)
      elsif WHITELISTED_BASE_CLASSES_FOR_PARAM_INSPECTION.any? { |klass| value.is_a?(klass) }
        formatted_value = value
      else
        formatted_value = "#<#{value.class}>"
      end

      params[key] = formatted_value
    end

    return params.inspect
  end
end

ActiveSupport.run_load_hooks(:rails_ops_op, RailsOps::Operation)
