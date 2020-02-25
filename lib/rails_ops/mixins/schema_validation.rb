# Mixin for the {RailsOps::Operation} class that provides a simple way of
# validation the params hash against a specific schema. It internally uses
# policies for running the validations (see {RailsOps::Mixins::Policies}).
module RailsOps::Mixins::SchemaValidation
  extend ActiveSupport::Concern

  included do
    class_attribute :_op_schema
    self._op_schema = nil
  end

  module ClassMethods
    # Creates a policy to validate the params hash against the given schema. See
    # {Schemacop::Validator} for more information on how schemas are built.
    #
    # Schemas are always validated on instantiation and, using defaults and
    # casts, can also alter the params hash assigned to the operation.
    #
    # Only one schema can be active at a time. Defining multiple schemata or
    # defining schemas in a subclass always override previously defined schemas.
    #
    # @param *args [Array] Parameters to pass at schema initialization
    # @yield Block to pass at schema initialization
    def schema(*args, &block)
      self._op_schema = Schemacop::Schema.new(*args, &block)
    end
  end
end
