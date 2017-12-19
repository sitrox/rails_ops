module RailsOps
  module ModelMixins
    module VirtualHasOne
      extend ActiveSupport::Concern

      module ClassMethods
        # TODO: Passing type Fixnum currently requires a monkey-patch of ActiveType.
        # This would need to be changed when releasing this functionality as a Gem.
        # See config/initializers/patch_active_type.rb and
        # https://github.com/remofritzsche/active_type/commit/fb8c2cb4cccaaec
        #
        # TODO: Document.
        def virtual_has_one(name, base_class, required: false, default: nil, type: Integer)
          fk = "#{name}_id"
          attribute fk, type, default: default

          if required
            validates fk, presence: true
          end

          belongs_to name, anonymous_class: base_class, foreign_key: fk, class_name: base_class.name

          return reflect_on_association(name)
        end
      end
    end
  end
end
