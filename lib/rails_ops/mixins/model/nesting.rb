module RailsOps::Mixins::Model::Nesting
  extend ActiveSupport::Concern

  included do
    class_attribute :_nested_model_ops
    self._nested_model_ops = {}.freeze

    attr_reader :nested_model_ops
  end

  module ClassMethods
    def nest_model_op(attribute, klass, lookup_via_id_on_update: true, &params_block)
      # ---------------------------------------------------------------
      # Make sure we're working with an extension /  copy
      # of the given model class
      # ---------------------------------------------------------------
      unless always_extend_model_class?
        fail 'This operation class must be configured to always extend the model class as `nest_model_op` modifies it.'
      end

      # ---------------------------------------------------------------
      # Validate association (currently, we only support belongs_to)
      # ---------------------------------------------------------------
      reflection = model.reflect_on_association(attribute)

      if reflection.nil?
        fail "Association #{attribute} could not be found for #{model.model_name}."
      elsif !reflection.belongs_to?
        fail 'Method nest_model_op only supports :belongs_to associations, '\
             "but association #{attribute} of model #{model.model_name} is a "\
             "#{reflection.macro} association."
      elsif reflection.options[:autosave] != false
        fail "Association #{attribute} of #{model.model_name} has :autosave turned on. "\
             'This is not supported by nest_model_op.'
      elsif !reflection.options[:validate]
        fail "Association #{attribute} of #{model.model_name} has :validate turned off. "\
        'This is not supported by nest_model_op.'
      end

      # ---------------------------------------------------------------
      # Define attributes setter on model.
      #
      # Model nesting is not compatible with accepts_nested_attributes_for
      # as it automatically enables :autosave which is not supported.
      # As we can't use accepts_nested_attributes_for, no nested attributes
      # setter is generated. This also means that `fields_for` in form
      # generation don't detect the attribute as nested and mistakenly omit the
      # _attributes suffix. Therefore, we define this method but fail if it
      # ever gets called.
      # ---------------------------------------------------------------
      model.send(:define_method, "#{attribute}_attributes=") do |_value|
        fail 'This operation model does not allow receiving nested attributes' \
             "for #{attribute}, as this is saved using a nested model operation."
      end

      # ---------------------------------------------------------------
      # Validate inverse association reflection if given
      # ---------------------------------------------------------------
      if (inverse_reflection = reflection.inverse_of)
        if inverse_reflection.options[:autosave] != false
          fail "Association #{inverse_reflection.name} of #{inverse_reflection.active_record} has :autosave turned on. "\
               'This is not supported by nest_model_op.'
        end
      end

      # ---------------------------------------------------------------
      # Store configuration
      # ---------------------------------------------------------------
      self._nested_model_ops = _nested_model_ops.merge(
        attribute => {
          klass: klass,
          params_proc: params_block,
          lookup_via_id_on_update: lookup_via_id_on_update
        }
      )
    end

    def nested_model_param_keys
      _nested_model_ops.keys.collect do |attribute|
        "#{attribute}_attributes"
      end
    end
  end

  def nested_model_ops_performed?
    @nested_model_ops_performed || false
  end

  protected

  def nested_model_op(attribute)
    fail 'Nested model operations have not been built yet.' unless @nested_model_ops
    return @nested_model_ops[attribute]
  end

  def build_nested_model_ops(action)
    # Validate action
    fail 'Unsupported action.' unless [:create, :update].include?(action)

    # Make sure that this method can only be run once per operation
    fail 'Nested model operations can only be built once.' if @nested_model_ops
    @nested_model_ops = {}

    self.class._nested_model_ops.each do |attribute, config|
      op_params = extract_attributes_from_params["#{attribute}_attributes"] || {}

      # Remove id field as this is commonly supplied by Rails' `fields_for` if
      # the nested model is persisted. We don't usually need this.
      op_params = op_params.except(:id)

      # Apply custom params processing callback if given
      if config[:params_proc]
        op_params = instance_exec(op_params, &config[:params_proc])
      end

      # Wrap parameters for nested model operation
      if action == :create
        wrapped_params = {
          attribute => op_params
        }
      elsif action == :update
        if config[:lookup_via_id_on_update]
          foreign_key = model.class.reflect_on_association(attribute).foreign_key
          id = model.send(foreign_key)
        else
          id = model.send(attribute).id
        end

        wrapped_params = {
          :id => id,
          attribute => op_params
        }
      else
        fail "Unsupported action #{action}."
      end

      # Instantiate nested operation
      @nested_model_ops[attribute] = sub_op(config[:klass], wrapped_params)

      # Inject model of nested operation to our own model
      nested_model = @nested_model_ops[attribute].model
      model.send("#{attribute}=", nested_model)

      # Inject our own model to model of nested operation (if the inverse
      # reflection can be resolved)
      if (inverse_reflection = model.class.reflect_on_association(attribute).inverse_of)
        nested_model.send("#{inverse_reflection.name}=", model)
      end
    end
  end

  # Tries to save nested models using their respective operations.
  def perform_nested_model_ops!
    fail 'Nested model operations can only be performed once.' if nested_model_ops_performed?

    # Validate the whole model hierarchy. Since we're calling 'model' here, this
    # line also makes sure a model is built.
    model.validate!

    # Make sure nested model operations are build
    fail 'Nested model operations are not built yet. Make sure the model is built.' unless @nested_model_ops

    @nested_model_ops.each do |attribute, op|
      # Run the nested model operation and fail hard if a validation error
      # arises. This should generally not happen as the whole hierarchy has been
      # validated before. It is vital that the transaction gets rolled back if
      # an exception happens here.
      begin
        op.run!
      rescue op.validation_errors => e
        fail RailsOps::Exceptions::SubOpValidationFailed, e
      end

      # Assign model again so that the ID gets updated
      model.send("#{attribute}=", op.model)
    end

    @nested_model_ops_performed = true
  end
end
