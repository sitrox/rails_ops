class RailsOps::Operation::Model::Load < RailsOps::Operation::Model
  class_attribute :_lock_model_at_build
  class_attribute :_load_model_authorization_action

  policy :on_init do
    model_authorization
  end

  # Gets or sets the action verb used for authorizing models on load.
  def self.load_model_authorization_action(*action)
    if action.size == 1
      self._load_model_authorization_action = action.first
    elsif action.size > 1
      fail ArgumentError, 'Too many arguments'
    end

    return _load_model_authorization_action
  end

  def model_authorization
    return unless authorization_enabled?

    unless load_model_authorization_action.nil?
      authorize_model! load_model_authorization_action, model
    end
  end

  def load_model_authorization_action
    self.class.load_model_authorization_action
  end

  load_model_authorization_action :read

  def self.lock_model_at_build(enabled = true)
    self._lock_model_at_build = enabled
  end

  def self.lock_model_at_build?
    _lock_model_at_build.nil? ? RailsOps.config.lock_models_at_build? : _lock_model_at_build
  end

  def model_id_field
    :id
  end

  def find_model
    unless params[model_id_field]
      fail "Param #{model_id_field.inspect} must be given."
    end

    # Get model class
    relation = self.class.model

    # Express intention to lock if required
    relation = relation.lock if self.class.lock_model_at_build?

    # Fetch (and possibly lock) model
    return relation.find_by!(model_id_field => params[model_id_field])
  end

  def build_model
    @model = find_model

    if @model.respond_to?(:parent_op=)
      @model.parent_op = self
    end
  end

  def extract_id_from_params
    params[model_id_field]
  end
end
