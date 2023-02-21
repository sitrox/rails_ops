class RailsOps::Operation::Model::Update < RailsOps::Operation::Model::Load
  model_authorization_action :update
  lock_mode :exclusive

  # As this operation might extend the model class, we need to make sure that
  # the operation works using an extended 'copy' of the given model class.
  def self.always_extend_model_class?
    true
  end

  policy :before_perform do
    if model_authorization_action && self.class._model_authorization_lazy
      authorize_model! model_authorization_action, model
    end
  end

  def model_authorization
    return unless authorization_enabled?

    if self.class._model_authorization_lazy
      if load_model_authorization_action.nil?
        fail RailsOps::Exceptions::NoAuthorizationPerformed,
             "Operation #{self.class.name} must specify a " \
             'load_model_authorization_action because model ' \
             'authorization is configured to be lazy.'
      else
        authorize_model! load_model_authorization_action, model
      end
    elsif !load_model_authorization_action.nil?
      authorize_model_with_authorize_only! load_model_authorization_action, model
    end

    unless model_authorization_action.nil? || self.class._model_authorization_lazy
      authorize_model! model_authorization_action, model
    end
  end

  def build_model
    super
    build_nested_model_ops :update
    assign_attributes
  end

  def perform
    save!
  end
end
