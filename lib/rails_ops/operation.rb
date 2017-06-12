class RailsOps::Operation
  include RailsOps::Mixins::Policies
  include RailsOps::Mixins::SubOps
  include RailsOps::Mixins::SchemaValidation
  include RailsOps::Mixins::Authorization
  include RailsOps::Mixins::RequireContext
  include RailsOps::Mixins::LogSettings

  WHITELISTED_BASE_CLASSES_FOR_PARAM_INSPECTION = [
    ActiveRecord::Base,
    String,
    Integer,
    Symbol
  ].freeze

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
    if context_or_params.is_a?(RailsOps::Context)
      context = context_or_params
    elsif context_or_params.is_a?(Hash) || context_or_params.is_a?(ActionController::Parameters)
      context = nil
      params = context_or_params
    end

    @performed = false
    @context = context || RailsOps::Context.new

    # Convert ActionController::Parameters to a regular hash as we want to
    # bypass Rails' strong parameters for operation use.
    if params.is_a?(ActionController::Parameters)
      params = params.permit!.to_h
    end

    # Remove web-specific param entries (such as `authenticity_token`)
    @params = params.to_h.with_indifferent_access.except(
      *ActionController::ParamsWrapper::EXCLUDE_PARAMETERS
    )

    run_policies :on_init
  end

  # Returns an array of exception classes that are considered as validation
  # errors.
  def validation_errors
    [RailsOps::Exceptions::ValidationFailed, ActiveRecord::RecordInvalid]
  end

  # Returns a copy of the operation's params, wrapped in an OpenStruct object.
  def osparams
    @osparams ||= OpenStruct.new(params)
  end

  # Return a hash of parameters with all sensitive data replaced.
  def filtered_params
    f = ActionDispatch::Http::ParameterFilter.new(Rails.application.config.filter_parameters)
    return f.filter(params)
  end

  # Runs the operation using {run!} but rescues certain exceptions. Returns
  # `true` on success, otherwise `false`.
  def run
    run!
    return true
  rescue validation_errors
    return false
  end

  # Runs the operation. This internally calls the {perform} method and can only
  # be called once per operation instance. This is a bang method that raises at
  # any validation exception.
  def run!
    ActiveSupport::Notifications.instrument('run.operation', operation: self) do
      ::RailsOps::Profiler.profile(object_id, inspect) do
        fail 'An operation can only be performed once.' if performed?
        @performed = true
        run_policies :before_perform
        perform
      end
    end

    trigger :after_run, after_run_trigger_params

    return self
  end

  # Returns the contents of the operation as a nicely formatted string.
  def inspect
    inspection = self.class.name
    if params
      inspection << " (#{inspect_params(filtered_params)})"
    end
    return inspection
  end

  # Determines if the operation has been performed yet.
  def performed?
    @performed
  end

  # Fails with an exception if the operation has not been performed yet.
  def check_performed!
    fail 'Operation has not yet been perfomed.' unless performed?
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
    RailsOps.hookup.trigger(self, event, params)
  end

  # Yields the given block and rethrows any possible exception as a
  # {RailsOps::Exceptions::RollbackRequired} exception.
  #
  # For illustration of potential use cases, consider the following example:
  #
  #     class User::Create < RailsOps::Operation::Model::Create
  #       def perform
  #         super # Saves the user
  #
  #         model.some_field = 'some value'
  #         model.save! # Throws validation error
  #       end
  #     end
  #
  #     User::Create.run(user: { some: :values })
  #
  # Since this operation is run without the bang method, validation errors are
  # caught and won't result in the transaction beeing rolled back. However, the
  # `super` call already saved the user while the exception happens only at
  # the manual call to `model.save!`. Thus the user will still be in the DB,
  # despite the fact that the second update didn't run.
  #
  # The correct example would therefore be:
  #
  #     class User::Create < RailsOps::Operation::Model::Create
  #       def perform
  #         super # Saves the user
  #
  #         with_rollback_on_exception do
  #           model.some_field = 'some value'
  #           model.save! # Throws validation error
  #         end
  #       end
  #     end
  #
  # This method is one possible solution for issue #28535. There might be a more
  # elegant and transparent approach as explained in the issue.
  def with_rollback_on_exception(&_block)
    yield
  rescue => e
    fail RailsOps::Exceptions::RollbackRequired, e
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
