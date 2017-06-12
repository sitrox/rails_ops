module RailsOps
  class Context < ActiveType::Object
    attribute :user
    attribute :ability
    attribute :op_chain, default: []
    attribute :session
    attribute :called_via_hook
    attribute :url_options

    # Returns a copy of the context with the given operation added to the
    # contexts operation chain.
    def spawn(op)
      return Context.new(
        user:            user,
        ability:         ability,
        session:         session,
        op_chain:        op_chain + [op],
        called_via_hook: false,
        url_options:     url_options
      )
    end

    # Runs the given operation in this particular context with the given args
    # using the non-bang `run` method.
    def run(op, *args)
      op.run(self, *args)
    end

    # Runs the given operation in this particular context with the given args
    # using the bang `run!` method.
    def run!(op, *args)
      op.run!(self, *args)
    end
  end
end
