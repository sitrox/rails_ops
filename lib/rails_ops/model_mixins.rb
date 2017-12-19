# A collection of mixins that are useful when using models in operations.
module RailsOps::ModelMixins
  extend ActiveSupport::Concern

  included do
    include ArExtension            # Provides correct behaviour of model_name when extending AR objects.
    include ParentOp               # Provides parent_op accessor.
    include VirtualAttributes      # Provides virtual attributes functionality.
    include VirtualHasOne          # Provides virtual_has_one.
  end
end
