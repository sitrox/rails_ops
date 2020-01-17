class RailsOps::Configuration < ActiveType::Object
  attribute :lock_models_at_build, :boolean, default: true
  attribute :authorization_backend, :string, default: nil
  attribute :trigger_hookups_without_authorization, :boolean, default: false
  attribute :ensure_authorize_called, :boolean, default: true
end
