module RailsOps
  module ModelMixins
    # 108386: This fixes an issue where operation models could not be marshalled
    #  when there is an attached parent_op, as the parent_op may contain hashes
    #  with default procs which is not supported by `Marshal.dump`. This mixin
    #  therefore excludes this instance variable from being dumped and loaded.
    module Marshalling
      UNMARSHALED_VARIABLES = %i(@parent_op).freeze

      extend ActiveSupport::Concern

      def marshal_dump
        instance_variables.reject { |m| UNMARSHALED_VARIABLES.include? m }.each_with_object({}) do |attr, vars|
          vars[attr] = instance_variable_get(attr)
        end
      end

      def marshal_load(vars)
        vars.each do |attr, value|
          instance_variable_set(attr, value) unless UNMARSHALED_VARIABLES.include?(attr)
        end
      end
    end
  end
end
