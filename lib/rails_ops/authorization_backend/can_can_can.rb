require 'cancan'

module RailsOps::AuthorizationBackend
  class CanCanCan < Abstract
    EXCEPTION_CLASS = 'CanCan::AccessDenied'.freeze

    def initialize
      unless defined?(CanCanCan)
        fail 'RailsOps is configured to use CanCanCan authorization'\
             "backend, but the Gem 'cancancan' does not appear to be installed."
      end
    end

    def authorize!(operation, *args)
      ability = operation.context.try(:ability) || fail(RailsOps::Exceptions::AuthorizationNotPerformable)
      ability.authorize!(*args)
    end
  end
end
