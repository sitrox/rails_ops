# Mixin for the {RailsOps::Operation::Model} class that provides the method
# {authorize_model!} which authorizes the operation's model class or instance
# against the authorization methods of {RailsOps::Mixins::Authorization}.
module RailsOps::Mixins::Model::Authorization
  extend ActiveSupport::Concern

  included do
    class_attribute :_model_authorization_action
    class_attribute :_model_authorization_lazy
  end

  module ClassMethods
    # Gets or sets the action verb used for authorizing models.
    def model_authorization_action(*action, lazy: false)
      if action.size == 1
        self._model_authorization_action = action.first
        self._model_authorization_lazy = lazy
      elsif action.size > 1
        fail ArgumentError, 'Too many arguments'
      end

      return _model_authorization_action
    end

    # This wraps the original method
    # {RailsOps::Mixins::ParamAuthorization::ClassClassMethods.authorize_param}
    # to automatically use `authorize_model_with_authorize_only` and pass the
    # operations `model` to it (besides the given `action` and optional,
    # additional `*args`.
    #
    # If a block or no action is given, the original method will be called. See
    # the original method documentation for more information.
    def authorize_param(path, action = nil, *args, &block)
      if block_given? || action.blank?
        super
      else
        super(path) do
          authorize_model_with_authorize_only!(
            action,
            model,
            *args
          )
        end
      end
    end
  end

  def model_authorization_action
    self.class.model_authorization_action
  end

  # Performs authorization on the given model using the {authorize?} method.
  # Models are casted using {cast_model_for_authorization} so that they can be
  # used for authorization. If no `model_class_or_instance` is given, the
  # {model} instance method will be used.
  def authorize_model!(action, model_class_or_instance = model, *extra_args)
    authorize! action, cast_model_for_authorization(model_class_or_instance), *extra_args
  end

  # Performs an authorization check like {authorize_model!}, but does not mark
  # this operation instance as checked. This means that there must be at least
  # one other authorization call within execution of this operation for the
  # operation not to fail.
  def authorize_model_with_authorize_only!(action, model_class_or_instance = model, *extra_args)
    authorize_only! action, cast_model_for_authorization(model_class_or_instance), *extra_args
  end

  private

  # Cast {ActiveType::Record} classes or instances to regular AR models in order
  # for cancan(can) to work properly. Classes and instances that are no active
  # type records will be returned as-is.
  def cast_model_for_authorization(model_class_or_instance)
    if model_class_or_instance.is_a?(Class)
      if model_class_or_instance.respond_to?(:extended_record_base_class)
        return model_class_or_instance.extended_record_base_class
      else
        return model_class_or_instance
      end
    elsif model_class_or_instance.class.respond_to?(:extended_record_base_class)
      model_class_or_instance.becomes(model_class_or_instance.class.extended_record_base_class)
    else
      model_class_or_instance
    end
  end
end
