module RailsOps
  module ModelMixins
    module VirtualModelName
      extend ActiveSupport::Concern

      included do
        class_attribute :virtual_model_name
        class_attribute :virtual_sti_name
      end

      module ClassMethods
        def model_name
          virtual_model_name || super
        end

        def sti_name
          virtual_sti_name || super
        end

        def find_sti_class(_type_name)
          self
        end
      end
    end
  end
end
