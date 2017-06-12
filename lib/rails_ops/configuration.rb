class RailsOps::Configuration < ActiveType::Object
  attribute :lock_models_at_build, :boolean, default: true
  attribute :authorization_backend, :string, default: nil
end
