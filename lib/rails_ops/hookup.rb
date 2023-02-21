class RailsOps::Hookup
  REQUEST_STORE_KEY = 'RailsOps::Hookup'.freeze
  CONFIG_PATH = 'config/hookup.rb'.freeze

  attr_reader :hooks

  def self.instance
    if defined?(Rails) && Rails.env.development?
      return RequestStore.store[REQUEST_STORE_KEY] ||= new
    else
      @instance ||= new
      return @instance
    end
  end

  def initialize
    @hooks = nil
    @drawn = false
    @config_loaded = false
  end

  def load_config
    unless @config_loaded
      @config_loaded = true

      if File.exist?(CONFIG_PATH)
        load Rails.root.join(CONFIG_PATH)
      else
        Rails.logger.debug "RailsOps could not find hookup #{CONFIG_PATH}, using empty hookup configuration."
        draw do
          # Empty
        end
      end
    end

    unless @drawn
      fail 'Hooks are not drawn.'
    end
  end

  def draw(&block)
    if @drawn
      fail "Hooks can't be drawn twice."
    end

    dsl = DSL.new(&block)
    dsl.validate!

    @hooks = dsl.hooks
    @drawn = true
  end

  def hooks_for(operation, event)
    load_config

    hooks = []

    @hooks.slice('*', operation.class.name).each_value do |hooks_by_event|
      hooks += hooks_by_event.slice('*', event).values.flatten || []
    end

    return hooks
  end

  def trigger_params
    {}
  end

  def trigger(operation, event, params)
    context = operation.context.spawn(operation)
    context.called_via_hook = true

    hooks_for(operation, event).each do |hook|
      if context.op_chain.collect(&:class).collect(&:to_s).include?(hook.target_operation)
        next
      end

      begin
        op_class = hook.target_operation.constantize
      rescue NameError
        fail "Could not find hook target operation #{hook.target_operation}."
      end

      op = op_class.new(context, params)

      begin
        op.run!
      rescue *op.validation_errors => e
        fail RailsOps::Exceptions::HookupOpValidationFailed, e
      end
    end
  end
end
