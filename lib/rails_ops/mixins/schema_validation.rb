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
    def schema2(*args, &block)
      self._op_schema = Schemacop::Schema.new(*args, &block)
    end

    def schema3(reference = nil, **options, &block)
      if reference
        self._op_schema = Schemacop::Schema3.new(:reference, options.merge(path: reference))
      else
        self._op_schema = Schemacop::Schema3.new(:hash, **options, &block)
      end
    end

    def schema(*args, &block)
      case RailsOps.config.default_schemacop_version
      when 2
        schema2(*args, &block)
      when 3
        schema3(*args, &block)
      else
        fail 'Schemacop schema versions supported are 2 and 3.'
      end
    end
  end
end
