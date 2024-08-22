module RailsOps
  module ModelMixins
    module VirtualHasOne
      extend ActiveSupport::Concern

      module ClassMethods
        def virtual_has_one(name, base_class, required: false, default: nil, type: Integer)
          RailsOps.deprecator.warn('virtual_has_one is deprecated and will be removed in a future version.')

          fk = "#{name}_id"
          attribute fk, type, default: default
          belongs_to name, anonymous_class: base_class, foreign_key: fk, class_name: base_class.name, required: required

          return reflect_on_association(name)
        end
      end
    end
  end
end
