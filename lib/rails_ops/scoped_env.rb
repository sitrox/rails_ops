module RailsOps
  class ScopedEnv
    def initialize(delegation_object, methods)
      @delegation_object = delegation_object
      @methods = methods
    end

    def method_missing(symbol, *args, &block)
      if @methods.include?(symbol)
        @delegation_object.send(symbol, *args, &block)
      else
        super
      end
    end

    def respond_to_missing?(symbol, include_private = false)
      @methods.include?(symbol) || super
    end
  end
end
