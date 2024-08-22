require 'active_type'
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

  # @private
  def self.deprecator
    @deprecator ||= ActiveSupport::Deprecation.new('2.0', 'RailsOps')
  end
end

# ---------------------------------------------------------------
# Require RailsOps
# ---------------------------------------------------------------
require 'rails_ops/authorization_backend/abstract'
require 'rails_ops/configuration'
require 'rails_ops/context'
require 'rails_ops/controller_mixin'
require 'rails_ops/exceptions'
require 'rails_ops/hooked_job' if defined?(ActiveJob)
require 'rails_ops/hookup'
require 'rails_ops/hookup/dsl'
require 'rails_ops/hookup/dsl_validator'
require 'rails_ops/hookup/hook'
require 'rails_ops/log_subscriber'
require 'rails_ops/mixins'
require 'rails_ops/mixins/authorization'
require 'rails_ops/mixins/param_authorization'
require 'rails_ops/mixins/log_settings'
require 'rails_ops/mixins/model'
require 'rails_ops/mixins/model/authorization'
require 'rails_ops/mixins/model/nesting'
require 'rails_ops/mixins/policies'
require 'rails_ops/mixins/require_context'
require 'rails_ops/mixins/routes'
require 'rails_ops/mixins/schema_validation'
require 'rails_ops/mixins/sub_ops'
require 'rails_ops/model_mixins'
require 'rails_ops/model_mixins/ar_extension'
require 'rails_ops/model_mixins/parent_op'
require 'rails_ops/model_mixins/sti_fixes'
require 'rails_ops/model_mixins/marshalling'
require 'rails_ops/model_mixins/virtual_attributes'
require 'rails_ops/model_mixins/virtual_attributes/virtual_column_wrapper'
require 'rails_ops/model_mixins/virtual_has_one'
require 'rails_ops/model_mixins/virtual_model_name'
require 'rails_ops/operation'
require 'rails_ops/operation/model'
require 'rails_ops/operation/model/load'
require 'rails_ops/operation/model/create'
require 'rails_ops/operation/model/destroy'
require 'rails_ops/operation/model/update'
require 'rails_ops/profiler'
require 'rails_ops/profiler/node'
require 'rails_ops/railtie' if defined?(Rails)
require 'rails_ops/scoped_env'
require 'rails_ops/virtual_model'
