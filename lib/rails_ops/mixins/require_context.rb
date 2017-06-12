# Mixin for the {RailsOps::Operation} class that provides *require_context*.
module RailsOps::Mixins::RequireContext
  extend ActiveSupport::Concern

  module ClassMethods
    # This DSL method allows you to make sure that a context is provided to your
    # operation. If used, it will fail at operation instantiation if no context
    # is provided. By providing one or more `attributes`, you can optionally
    # specify which context attributes need to be present (not nil).
    #
    # This can be useful to fail early if you're going to be accessing e.g.
    # `context.user` and `context.session`. In this case, you can specify:
    #
    # ```ruby
    # class MyOp < RailsOps::Operation
    #   require_context :user, :session
    # end
    # ```
    #
    # @param args [Array<Symbol>] Specify which context attributes need to be
    #   present
    def require_context(*attributes)
      policy :on_init do
        attributes.each do |attribute|
          if context.attributes[attribute.to_s].nil?
            fail RailsOps::Exceptions::MissingContextAttribute,
                 "This operation requires the context attribute #{attribute.inspect} to be present."
          end
        end
      end
    end
  end
end
