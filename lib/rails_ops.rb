require 'schemacop'
require 'request_store'

module RailsOps
  AUTH_THREAD_STORAGE_KEY = :rails_ops_authorization_enabled

  def self.config
    @config ||= Configuration.new
  end

  def self.configure(&_block)
    yield(config)
  end

  def self.authorization_backend
    return nil unless config.authorization_backend
    return @authorization_backend ||= config.authorization_backend.constantize.new
  end

  # Returns an instance of the {RailsOps::Hookup} class. This instance is
  # cached depending on the application environment.
  def self.hookup
    Hookup.instance
  end

  def self.authorization_enabled?
    return false unless authorization_backend

    if Thread.current[AUTH_THREAD_STORAGE_KEY].nil?
      return true
    else
      return Thread.current[AUTH_THREAD_STORAGE_KEY]
    end
  end

  # Operations within the given block will have disabled authorization.
  # This only applies to the current thread.
  def self.without_authorization(&_block)
    previous_value = Thread.current[AUTH_THREAD_STORAGE_KEY]
    Thread.current[AUTH_THREAD_STORAGE_KEY] = false
    begin
      yield
    ensure
      Thread.current[AUTH_THREAD_STORAGE_KEY] = previous_value
    end
  end
end

# ---------------------------------------------------------------
# Require Gem active_type and monkey patch
# ---------------------------------------------------------------
require 'active_type'
require 'active_type/type_caster'
require 'rails_ops/patches/active_type_patch'

# ---------------------------------------------------------------
# Require Schemacop
# ---------------------------------------------------------------
require 'schemacop'

# ---------------------------------------------------------------
# Require RailsOps
# ---------------------------------------------------------------
require 'rails_ops/authorization_backend/abstract.rb'
require 'rails_ops/configuration.rb'
require 'rails_ops/context.rb'
require 'rails_ops/controller_mixin.rb'
require 'rails_ops/exceptions.rb'
require 'rails_ops/hooked_job.rb' if defined?(ActiveJob)
require 'rails_ops/hookup.rb'
require 'rails_ops/hookup/dsl.rb'
require 'rails_ops/hookup/dsl_validator.rb'
require 'rails_ops/hookup/hook.rb'
require 'rails_ops/log_subscriber.rb'
require 'rails_ops/mixins.rb'
require 'rails_ops/mixins/authorization.rb'
require 'rails_ops/mixins/param_authorization.rb'
require 'rails_ops/mixins/log_settings.rb'
require 'rails_ops/mixins/model.rb'
require 'rails_ops/mixins/model/authorization.rb'
require 'rails_ops/mixins/model/nesting.rb'
require 'rails_ops/mixins/policies.rb'
require 'rails_ops/mixins/require_context.rb'
require 'rails_ops/mixins/routes.rb'
require 'rails_ops/mixins/schema_validation.rb'
require 'rails_ops/mixins/sub_ops.rb'
require 'rails_ops/model_casting.rb'
require 'rails_ops/model_mixins.rb'
require 'rails_ops/model_mixins/ar_extension.rb'
require 'rails_ops/model_mixins/parent_op.rb'
require 'rails_ops/model_mixins/virtual_attributes.rb'
require 'rails_ops/model_mixins/virtual_attributes/virtual_column_wrapper.rb'
require 'rails_ops/model_mixins/virtual_has_one.rb'
require 'rails_ops/model_mixins/virtual_model_name.rb'
require 'rails_ops/operation.rb'
require 'rails_ops/operation/model.rb'
require 'rails_ops/operation/model/load.rb'
require 'rails_ops/operation/model/create.rb'
require 'rails_ops/operation/model/destroy.rb'
require 'rails_ops/operation/model/update.rb'
require 'rails_ops/profiler.rb'
require 'rails_ops/profiler/node.rb'
require 'rails_ops/railtie.rb' if defined?(Rails)
require 'rails_ops/scoped_env.rb'
require 'rails_ops/virtual_model.rb'
