module RailsOps::AuthorizationBackend
  class Abstract
    def authorize!(_operation, *_args)
      fail NotImplementedError
    end
  end
end
