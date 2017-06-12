# Mixin for the {RailsOps::Operation} class that provides basic authorization
# methods based on the cancan(can) ability that can be provided using an
# operation's context.
module RailsOps::Mixins::Authorization
  extend ActiveSupport::Concern

  included do
    class_attribute :_authorization_disabled
    class_attribute :_authorization_disabled_for_sub_ops

    policy :after_perform do
      ensure_authorize_called!
    end
  end

  module ClassMethods
    # Disables authorization (and authorization check) for this
    # operation. If `include_sub_ops` is `true` (default `false`),
    # this setting also applies to sub operations called by this
    # operation (either via run_sub(!) or via a hook).
    def without_authorization(include_sub_ops: false)
      fail 'Option include_sub_ops is not yet supported.' if include_sub_ops

      self._authorization_disabled = true
      self._authorization_disabled_for_sub_ops = include_sub_ops
    end
  end

  # Checks whether authorization is currently enabled and possible
  # (an ability is present).
  def authorization_enabled?
    # Do not perform authorization if it is disabled globally
    return false unless RailsOps.authorization_enabled?

    # Do not perform authorization if it is disabled for this operation
    return false if self.class._authorization_disabled

    # Do not perform authorization if no ability is present
    return false unless context.ability

    # Perform authorization
    return true
  end

  def authorization_enabled_for_sub_ops?
    !@_authorization_disabled_for_sub_ops
  end

  def authorize_called?
    @_authorize_called ||= false
  end

  # Operations within the given block will have disabled authorization.
  # This only applies to the current thread.
  def without_authorization(&block)
    RailsOps.without_authorization(&block)
  end

  # Checks authorization against the configured authentication backend. Fails if
  # authentication is not successfull or could not be performed. Does not
  # perform anything if authorization is disabled.
  def authorize!(action, *args)
    authorize_only!(action, *args)
    @_authorize_called = true
  end

  # Checks authorization against the configured authentication backend. Fails if
  # authentication is not successfull or could not be performed. Does not
  # perform anything if authorization is disabled. Calling authorize_only! does
  # not count as authorized concerning ensure_authorize_called!.
  def authorize_only!(*args)
    return unless authorization_enabled?
    RailsOps.authorization_backend.authorize!(self, *args)
  end

  # Checks if an authentication check has been performed if authorization is
  # enabled.
  def ensure_authorize_called!
    return unless authorization_enabled?
    return if authorize_called?
    fail RailsOps::Exceptions::NoAuthorizationPerformed, "Operation #{self.class.name} has been performed without authorization."
  end
end
