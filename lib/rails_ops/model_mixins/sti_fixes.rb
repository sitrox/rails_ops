module RailsOps
  module ModelMixins
    module StiFixes
      extend ActiveSupport::Concern

      class_methods do
        def finder_needs_type_condition?
          base_class.finder_needs_type_condition?
        end

        def name
          base_class.name
        end
      end
    end
  end
end
