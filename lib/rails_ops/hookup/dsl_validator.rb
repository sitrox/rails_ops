class RailsOps::Hookup::DSLValidator
  attr_reader :error
  attr_reader :trace

  def initialize(hooks)
    @hooks = hooks
    @trace = []
  end

  def validate!
    # Check infinity loop
    if target_hooks.any? { |name, targets| recursion?(targets, name) }
      fail SystemStackError.new, "Infinite loop detected in hooks configuration: #{inspect_trace}."
    end
  end

  def target_hooks
    @target_hooks ||= @hooks.map do |name, hash|
      [name, drilldown(hash)]
    end.to_h
  end

  private

  def inspect_trace
    @trace.map(&:to_s).join(' ~> ')
  end

  def recursion?(targets, name)
    if targets.include? name
      @trace << name.to_s
      return true
    end

    return targets.any? do |target|
      if @hooks[target]
        @trace |= [name, target]
        recursion? drilldown(@hooks[target]), name
      end
    end
  end

  def drilldown(hash)
    hash.values.flatten.map(&:target_operation)
  end
end
