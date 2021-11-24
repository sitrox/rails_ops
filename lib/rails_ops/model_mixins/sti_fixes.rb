module RailsOps
  module ModelMixins
    module StiFixes
      extend ActiveSupport::Concern

      class_methods do
        def finder_needs_type_condition?
          superclass.finder_needs_type_condition?
        end

        def descendants
          superclass.descendants
        end

        def name
          superclass.name
        end
      end
    end
  end
end
