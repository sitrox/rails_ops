# When extending an ActiveRecord::Base model class, you can mix this module
# into the extending class to make it behave like it was the original one
# in terms of it's model_name identity.
#
# Note that you have to mix this in directly into the first class inheriting
# from your real model class.
module RailsOps::ModelMixins::ArExtension
  extend ActiveSupport::Concern

  included do
    class_attribute :extended_record_base_class
    self.extended_record_base_class = superclass
  end

  module ClassMethods
    def model_name
      (extended_record_base_class || superclass).model_name
    end
  end
end
