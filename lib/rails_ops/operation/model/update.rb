class RailsOps::Operation::Model::Update < RailsOps::Operation::Model::Load
  model_authorization_action :update
  lock_mode :exclusive

  # As this operation might extend the model class, we need to make sure that
  # the operation works using an extended 'copy' of the given model class.
  def self.always_extend_model_class?
    true
  end

  policy :on_init do
    if self.class._model_authorization_lazy && load_model_authorization_action.nil?
      fail RailsOps::Exceptions::NoAuthorizationPerformed,
           "Operation #{self.class.name} must specify a " \
           'load_model_authorization_action because model ' \
           'authorization is configured to be lazy.'
    end
  end

  def model_authorization
    if authorization_enabled? && model_authorization_action.present?
      authorize_model! model_authorization_action, model
    end
  end

  def build_model
    # Load model via parent class
    super

    # Build nested model operations
    build_nested_model_ops :update

    # Perform update authorization BEFORE assigning attributes
    unless self.class._model_authorization_lazy
      model_authorization
    end

    # Assign attributes
    assign_attributes
  end

  def perform
    save!
  end
end
