class RailsOps::Hookup::Hook
  attr_reader :on_operation
  attr_reader :on_event
  attr_reader :target_operation

  def initialize(on_operation, on_event, target_operation)
    @on_operation              = on_operation
    @on_event                  = on_event
    @target_operation          = target_operation
  end
end
