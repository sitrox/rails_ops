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
    def schema(reference = nil, version: nil, **options, &block)
      if reference
        if version && version != 3
          fail 'References are only supported with schemacop schema version 3.'
        end

        self._op_schema = Schemacop::Node.create(:reference, path: reference)
      else
        version ||= RailsOps.config.default_schemacop_version

        if version == 3
          self._op_schema = Schemacop::Node.create(:object, options, &block)
        elsif version == 2
          if defined?(Schemacop::V2)
            self._op_schema = Schemacop::V2::Schema.new(:hash, options, &block)
          else
            self._op_schema = Schemacop::Schema.new(:hash, options, &block)
          end
        elsif
          fail "Unsupported schemacop schema version #{version}. Schemacop supports 2 and 3."
        end
      end
    end
  end
end
