module RailsOps
  module ControllerMixin
    extend ActiveSupport::Concern

    # TODO: A similar thing is already done in the operation
    #   initializer. Are both necessary? This one here contains
    #   more exceptions though.
    EXCEPT_PARAMS = [
      :controller,
      :action,
      :utf8,
      :authenticity_token,
      :escape,
      :_referer_depth,
      :_referer,
      :_method,
      :_ # jQuery.ajax cache: false
    ].freeze

    included do
      if defined?(helper_method)
        helper_method :model
        helper_method :op
        helper_method :op?

        after_action :ensure_operation_authorize_called!
      end
    end

    # Instantiates and returns a new operation with the given class. If no class
    # is given, it just returns the previously assigned operation or raises if
    # none has been given.
    def op(op_class = nil, custom_params = nil)
      set_op_class(op_class, custom_params) if op_class
      fail 'Operation is not set.' unless @op
      return @op
    end

    # Determines whether an operation has been set.
    def op?
      !!@op
    end

    # If there is a current operation set, it is made sure that authorization
    # has been performed within the operation. This only applies if
    # authorization is not disabled.
    def ensure_operation_authorize_called!
      return unless op?
      op.ensure_authorize_called!
    end

    # Runs an operation and fails on validation errors using an exception. If
    # no operation class is given, it takes the operation previosly set by {op}
    # or fails if no operation has been set. If an op_class is given, it will be
    # set using the {op} method.
    def run!(op_class = nil, custom_params = nil)
      op(op_class, custom_params) if op_class
      op.run!
    end

    # Runs an operation and returns `true` for success and `false` for any
    # validation errors. The supplied block is yielded only on success.
    # See {run!} for more information.
    def run(op_class = nil, custom_params = nil, &_block)
      op(op_class, custom_params) if op_class
      success = op.run
      yield if success && block_given?
      return success
    end

    # Returns the current operation's `model`. Fails with an exception if the
    # current operation does not respond to the `model` (i.e. is not a model
    # operation).
    def model
      return @model if @model
      fail 'Current operation does not support `model` method.' unless op.respond_to?(:model)
      return op.model
    end

    # Filters the `params` hash for use with RailsOps. This removes certain
    # web-specific parameters based on `EXCEPT_PARAMS`.
    def filter_op_params(params)
      (params || {}).except(*EXCEPT_PARAMS)
    end

    # Filters operation params using `filter_op_params`, permits them using
    # strong params and converts them to a hash. This method can be overridden
    # for passing custom params to an operation for an entire controller.
    def op_params
      @op_params ||= filter_op_params(params.permit!).to_h
    end

    # Constructs and returns the operation context used for instantiating
    # operations from within this controller.
    def op_context
      @op_context ||= begin
        context = RailsOps::Context.new
        context.user = current_user if defined?(:current_user)
        context.ability = current_ability if defined?(:current_ability)
        context.session = session
        context.url_options = url_options
        context.view = view
        context
      end
    end

    protected

    def set_op_class(op_class, custom_params = nil)
      fail 'Operation class is already set.' if @op_class
      @op_class = op_class
      @op = instantiate_op(custom_params)
    end

    def instantiate_op(custom_params = nil)
      return @op_class.new(op_context, custom_params || op_params)
    end
  end
end
