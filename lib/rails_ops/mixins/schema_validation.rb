# Mixin for the {RailsOps::Operation} class that provides a simple way of
# validation the params hash against a specific schema. It internally uses
# policies for running the validations (see {RailsOps::Mixins::Policies}).
module RailsOps::Mixins::SchemaValidation
  extend ActiveSupport::Concern

  module ClassMethods
    # Creates a policy to validate the params hash against the given schema. See
    # {Schemacop::Validator} for more information on how schemas are built.
    #
    # Using `policy_chain`, you can control when the validation is performed.
    # Per default, validation is done before performing the operation.
    #
    # @param *args [Array] Parameters to pass at schema initialization
    # @param policy_chain [Symbol] The policy chain to perform the schema validation in
    # @yield Block to pass at schema initialization
    def schema(*args, policy_chain: :before_perform, &block)
      full_schema = Schemacop::Schema.new(*args, &block)

      policy policy_chain do
        full_schema.validate!(params)
      end
    end
  end
end
