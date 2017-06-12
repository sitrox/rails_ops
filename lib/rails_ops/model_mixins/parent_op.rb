# This is automatically mixed into every model passed to an operation
# and provides the :parent_op accessor that is set to the enclosing
# operation's instance.
module RailsOps::ModelMixins::ParentOp
  extend ActiveSupport::Concern

  included do
    attr_accessor :parent_op
  end
end
