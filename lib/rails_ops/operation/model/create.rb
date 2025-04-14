class RailsOps::Operation::Model::Create < RailsOps::Operation::Model
  model_authorization_action :create

  policy :on_init do
    model_authorization
  end

  # As this operation might extend the model class, we need to make sure that
  # the operation works using an extended 'copy' of the given model class.
  def self.always_extend_model_class?
    true
  end

  def model_authorization
    return unless authorization_enabled?

    unless model_authorization_action.nil?
      authorize_model! model_authorization_action, model
    end
  end

  def build_model
    fail 'Model can only be built once.' if defined?(@model) && @model
    @model = self.class.model.new
    if @model.respond_to?(:parent_op=)
      @model.parent_op = self
    end
    build_nested_model_ops :create
    assign_attributes
  end

  def perform
    save!
  end
end

ActiveSupport.run_load_hooks(:rails_ops_op_model_create, RailsOps::Operation::Model::Create)
