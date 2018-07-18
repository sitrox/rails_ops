module RailsOps
  module ModelMixins
    module VirtualModelName
      extend ActiveSupport::Concern

      included do
        class_attribute :virtual_model_name
      end

      module ClassMethods
        def model_name
          virtual_model_name || super
        end
      end
    end
  end
end
