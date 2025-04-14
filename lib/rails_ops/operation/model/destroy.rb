class RailsOps::Operation::Model::Destroy < RailsOps::Operation::Model::Load
  def self.model_authorization_action(*args, **kwargs, &block)
    original_authorization_action(*args, **kwargs, &block)
  end

  model_authorization_action :destroy
  lock_mode :exclusive

  def model_authorization
    return unless authorization_enabled?

    unless load_model_authorization_action.nil?
      authorize_model_with_authorize_only! load_model_authorization_action, model
    end

    unless model_authorization_action.nil?
      authorize_model! model_authorization_action, model
    end
  end

  policy do
    if model.respond_to?(:deleteable?) && !model.deleteable?
      fail RailsOps::Exceptions::ModelNotDeleteable
    end
  end

  def build_model
    super
    model_authorization
  end

  def perform
    trigger :before_destroy, model: model
    model.destroy!
  end
end

ActiveSupport.run_load_hooks(:rails_ops_op_model_destroy, RailsOps::Operation::Model::Destroy)
