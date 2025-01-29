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

  policy :before_perform do
    # If the authorization is configured to be lazy, we need to call the authorization
    # on a fresh copy of the model, before assigning the attributes. We simply use the `find_model`
    # method from our parent class and then run the authorization on this instance.
    if self.class._model_authorization_lazy
      model_from_database = find_model

      if model_from_database.respond_to?(:parent_op=)
        model_from_database.parent_op = self
      end

      authorize_model! model_authorization_action, model_from_database
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

    # Perform update authorization BEFORE assigning attributes. If the authorization is lazy,
    # we'll call the authorization later on in the `before_perform` block.
    model_authorization unless self.class._model_authorization_lazy

    # Assign attributes
    assign_attributes
  end

  def perform
    save!
  end
end
