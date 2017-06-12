module RailsOps::Exceptions
  class Base < StandardError; end
  class ValidationFailed < Base; end
  class ModelNotDeleteable < Base; end
  class AuthorizationNotPerformable < Base; end
  class NoAuthorizationPerformed < Base; end
  class MissingContextAttribute < Base; end
  class RoutingNotAvailable < Base; end
  class RollbackRequired < Base; end

  class SubOpValidationFailed < Base
    attr_reader :original_exception

    def initialize(original_exception)
      @original_exception = original_exception
      super original_exception.message
    end
  end
end
