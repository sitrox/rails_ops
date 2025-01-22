class RailsOps::Operation::Model::Load < RailsOps::Operation::Model
  class_attribute :_lock_model_at_build
  class_attribute :_load_model_authorization_action
  class_attribute :_lock_mode

  policy :on_init do
    model
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

  def load_model_authorization
    if authorization_enabled? && load_model_authorization_action.present?
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

  def lock_model_at_build?
    self.class._lock_model_at_build?
  end

  # Method to set the lock mode, which can either be :exclusive to use
  # an exclusive write lock, or :shared to use a shared lock. Please note
  # that currently, :shared only works for MySql, Postgresql and Oracle DB,
  # other adapters always use the exclusive lock.
  def self.lock_mode(lock_mode)
    fail "Unknown lock mode #{lock_mode}" unless %i[shared exclusive].include?(lock_mode)

    self._lock_mode = lock_mode
  end

  # Get the lock_mode or the default of :exclusive
  def self.lock_mode_or_default
    _lock_mode.presence || :exclusive
  end

  # Set the lock mode for load operations (and it's children) to :shared
  lock_mode :shared

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
    relation = lock_relation(relation)

    # Fetch (and possibly lock) model
    model = relation.find_by!(model_id_field => params[model_id_field])

    # Return model
    return model
  end

  def build_model
    @model = find_model

    # Perform load model authorization
    load_model_authorization

    if @model.respond_to?(:parent_op=)
      @model.parent_op = self
    end
  end

  def extract_id_from_params
    params[model_id_field]
  end

  private

  def lock_relation(relation)
    # Directly return the relation if we don't want to lock the relation
    return relation unless lock_model_at_build?

    if self.class.lock_mode_or_default == :shared
      # Lock the relation in shared mode
      return relation.lock(shared_lock_statement)
    else
      # Lock the relation in exclusive mode
      return relation.lock
    end
  end

  def shared_lock_statement
    adapter_type = ActiveRecord::Base.connection.adapter_name.downcase.to_sym

    case adapter_type
    when :mysql, :mysql2, :oracleenhanced
      return 'LOCK IN SHARE MODE'
    when :postgresql
      return 'FOR SHARE'
    end

    # Don't return anything, which will make the `lock` statement
    # use the normal, exclusive lock. This might be suboptimal for other
    # database adapters, but we'd rather lock too restrictive, such that
    # no race-conditions may occur.
    return nil
  end
end
