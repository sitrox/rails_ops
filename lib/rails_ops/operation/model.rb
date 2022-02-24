class RailsOps::Operation::Model < RailsOps::Operation
  include RailsOps::Mixins::Model::Authorization
  include RailsOps::Mixins::Model::Nesting

  class_attribute :_model_class
  class_attribute :_lazy_model

  # Works like `model` method (see its documentation), but takes a string as
  # model class and constructs the effective model class lazily on first
  # invocation of the `model` method (without params).
  def self.lazy_model(model_class_name = nil, name = nil, &block)
    self._lazy_model = {
      model_class_name: model_class_name,
      name:             name,
      block:            block
    }
  end

  # Allows to set or get a model class associated with this operation.
  #
  # To get the model class, call this method without any parameters. Note that
  # this will result in an exception if the model class has not been previously
  # set.
  #
  # To set the model class, there are 3 ways:
  #
  # - You only specify an existing class as `model_class`.
  # - You only specify a block of code. This will result in a dynamically
  #   created class using the provided code block. The base class that is
  #   extended by this block is determined by the method
  #   {default_model_class}. Check this method to determine the used base class
  #   or overwrite it. This only makes sense for inheritance as there is the
  #   parameter `model_class` (see next point).
  # - You specify a `model_class` as well as a block of code. In this case, the
  #   supplied class will be dynamically extended with the code block provided.
  #
  # This is a DSL method. Do not call it at runtime (i.e. after bootup) as it
  # is not thread-safe and may generate anonymous classes.
  #
  # @param model_class [Class] The model class to take or extend
  # @param name [String,Symbol] A custom name that will be used for generating
  #   the anonymous class
  # @yield [] This optional block is executed in context of the newly generated,
  #   anonymous class and allows you to extend it
  def self.model(model_class = nil, name = nil, &block)
    if model_class || block_given?
      fail 'Model class can only be set once.' if _model_class

      model_class ||= default_model_class

      # ---------------------------------------------------------------
      # If we're given a block or we're configured to always extend the
      # given model class, create a new model class inheriting from the
      # given one and mix in required modules.
      # ---------------------------------------------------------------
      if block_given? || always_extend_model_class? || name
        self._model_class = Class.new(model_class)

        # Include operation mixins that provide various functionality needed for
        # operation-specific models. We can safely include this even if it has
        # already been included, as module includes only happen once.
        _model_class.send(:include, RailsOps::ModelMixins)

        # Apply the given block to the newly created class.
        _model_class.class_eval(&block) if block_given?

        # Set virtual model name if given.
        if name && _model_class.respond_to?(:virtual_model_name=)
          _model_class.virtual_model_name = ActiveModel::Name.new(_model_class, nil, name.to_s)
        end

        # Set virtual STI name if given.
        if model_class && model_class.name
          _model_class.virtual_sti_name = model_class.name
        end

      # ---------------------------------------------------------------
      # We just use the given model class without any adaptions
      # ---------------------------------------------------------------
      else
        self._model_class = model_class
      end
    elsif _lazy_model && _model_class.nil?
      return model(_lazy_model[:model_class_name].safe_constantize, _lazy_model[:name], &_lazy_model[:block])
    elsif _model_class.nil?
      fail 'No model class has been set.'
    end

    return _model_class
  end

  # This method determines whether the given model class (specified using the
  # static `model` method) is always extended with an anonymous class. This can
  # be required if the operation modifies the model class.
  def self.always_extend_model_class?
    false
  end

  # Returns the class used for extension when defining a model using the {model}
  # method.
  def self.default_model_class
    ActiveType::Object
  end

  # Returns an instance of the operation model class. The instance is obtained
  # using {build_model} and cached for the lifespan of the operation instance.
  def model
    build_model unless defined?(@model) && @model
    return @model
  end

  # Assigns attributes to a model. If no arguments are given, it extracts the
  # attributes from the {params} hash and assigns them to the {model}.
  #
  # @param attributes [Hash] The attributes hash to assign. If not given,
  #   attributes will be obtained from the {params} hash using
  #   {extract_attributes_from_params}.
  # @param without_protection [Boolean] If `true`, attributes wil be assigned without
  #   mass assignment protection.
  # @param model [ActiveRecord::Base] Allows to manually specify a model the attributes
  #   will be assigned to. If not given, the model will be obtained from the
  #   {model} method.
  # @param without_nested_models [Boolean] Per default, attribute params that
  #   are meant for nested models (registered via `nested_model_op`) will not
  #   be assigned. You can turn this filtering off by passing `false`.
  def assign_attributes(attributes = nil, model: nil, without_protection: false, without_nested_models: true)
    model ||= self.model

    attributes ||= extract_attributes_from_params(model)

    if without_nested_models
      # Remove parameters that will be passed to nested model operations
      # such as `post_attributes: {}`.
      attributes = attributes.except(*self.class.nested_model_param_keys)
    end

    # Assign the "type" attribute if we need it
    if _model_class.superclass.finder_needs_type_condition?
      attributes[_model_class.inheritance_column] ||= _model_class.superclass.name
    end

    # Do nothing if there are no attributes to assign
    return if attributes.nil? || attributes.empty?

    # Assign attributes, either with or without protection
    if !without_protection && model.respond_to?(:assign_attributes_with_protection)
      model.assign_attributes_with_protection(attributes)
    else
      model.assign_attributes(attributes)
    end
  end

  # Extracts model attributes from the {params} hash using
  # `model.model_name.param_key`. If no model is given, the model will be
  # obtained from the {model} method.
  # @param model [ActiveRecord::Base] An optional model for determining the
  #   param key name
  def extract_attributes_from_params(model = nil)
    model ||= self.model
    return params[model.model_name.param_key] || {}
  end

  protected

  # Performs nested model operations and then saves the model. If you have
  # nested model operations, you should call this method instead of calling
  # `model.save!` directly.
  def save!
    run_policies :before_nested_model_ops
    perform_nested_model_ops!
    run_policies :before_model_save
    model.save!
  end

  # Override of the base classes method to provide the model under key `model`
  # to operations called via the `after_run` hook. You can still override this
  # to suit your own operation's needs.
  def after_run_trigger_params
    { model: model }
  end

  # This method must be implemented on superclasses in order to return an
  # instance of the operation model class. This can be a new or existing record,
  # depending on the respective operation's needs.
  def build_model
    fail NotImplementedError, 'Method `build_model` must be implemented.'
  end
end
