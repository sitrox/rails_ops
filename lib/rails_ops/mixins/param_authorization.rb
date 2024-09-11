module RailsOps::Mixins::ParamAuthorization
  extend ActiveSupport::Concern

  included do
    class_attribute :_param_authorizations

    self._param_authorizations = [].freeze
  end

  module ClassMethods
    # Call this method to perform authorization if a specific parameter is
    # passed in the operations `params` hash.
    #
    # Note that this does not work for params contained in other structures than
    # nested hashes. I.e. params within arrays can not be extracted.
    #
    # @param path [Array] An array, usually of symbols or strings, which can be
    #   used to dig for the respective parameter you want to authorize.
    #
    # @param action [Object] The `action` passed to the authorization backend.
    #
    # @param *args [Array<Object>] Additional arguments passed to the
    #   authorization backend.
    #
    # @yield A block used for custom authorization. The block is only called if
    #   the specified parameter is contained in the `params` hash and is supposed
    #   to throw an authorization exception if the authorization failed. The
    #   exception must be of the exception class specified in your configured
    #   authorization backend. The block receives no arguments and is executed
    #   in context of the operation instance.
    def authorize_param(path, action = nil, *args, &block)
      path = Array(path)

      # Validate parameters
      if block_given? && (action || args.any?)
        fail ArgumentError,
             'If you pass an authorization block, no action and additional args are supported.'
      elsif !block_given? && !action
        fail ArgumentError,
             'You need to supply an action and additional args if no authorization block is provided.'
      end

      policy :on_init do
        # Abort unless param is given
        if path.size > 1
          next unless params.dig(*path[0..-2])&.include?(path.last)
        else
          next unless params.include?(path.first)
        end

        # Check authorization
        exception_class = RailsOps.authorization_backend.exception_class

        begin
          if block_given?
            instance_exec(&block)
          else
            authorize_only!(action, *args)
          end
        rescue exception_class
          fail exception_class, "Got unauthorized param #{path.join('.').inspect}."
        end
      end
    end
  end
end
