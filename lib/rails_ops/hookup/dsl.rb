class RailsOps::Hookup::DSL
  attr_reader :hooks

  def initialize(&block)
    @current_target            = nil
    @validator                 = nil
    @hooks                     = ActiveSupport::OrderedHash.new

    RailsOps::ScopedEnv.new(self, [:run]).instance_exec(&block)
  end

  def run(target, &block)
    @current_target = target
    RailsOps::ScopedEnv.new(self, [:on]).instance_exec(&block)
    @current_target = nil
  end

  def on(source, event = :after_run)
    @hooks[source] ||= ActiveSupport::OrderedHash.new
    @hooks[source][event] ||= []
    @hooks[source][event] << RailsOps::Hookup::Hook.new(source, event, @current_target)
  end

  def validate!
    @validator = RailsOps::Hookup::DSLValidator.new @hooks
    @validator.validate!
    @validator
  end
end
