# This mixin can be used with any Activemodel Model to allow mass assignment
# security. This is a simpler implementation of Rails' former mass assignment
# security functionality.
#
# Attribute protection is disabled per default. It can be enabled by either
# calling `attr_protection true` or one of `attr_accessible` and
# `attr_protected`.
module RailsOps::ModelMixins::ProtectedAttributes
  extend ActiveSupport::Concern

  included do
    class_attribute :accessible_attributes
    self.accessible_attributes = nil
  end

  # TODO: Document.
  def assign_attributes_with_protection(attributes)
    self.class._verify_protected_attributes!(attributes.dup)
    assign_attributes(attributes)
  end

  module ClassMethods
    # Returns whether attribute protection is enabled for this model.
    def attr_protection?
      !accessible_attributes.nil?
    end

    # Performs attribute protection verification (if enabled, see
    # {attr_protection?}). If forbidden attributes are found, an
    # {ActiveModel::ForbiddenAttributesError} exception is thrown.
    def _verify_protected_attributes!(attributes) # :nodoc:
      return unless attr_protection?

      received_keys = attributes.keys.map(&:to_sym).to_set

      disallowed_attributes = received_keys - accessible_attributes

      if disallowed_attributes.any?
        fail ActiveModel::ForbiddenAttributesError,
             "The following attributes are forbidden to be assigned to #{model_name}: " \
             "#{disallowed_attributes.to_a}, allowed are: #{accessible_attributes.to_a}."
      end
    end

    # Specifically turn on or off attribute protection for this model (and
    # models inheriting from it without overriding this setting).
    #
    # Note that attribute protection is turned on automatically when calling
    # {attr_accessible} or {attr_protected}.
    #
    # If you're using this method to turn protection off, the list of accessible
    # attributes is wiped. So if you re-enable it, no attributes will be
    # accessible.
    def attr_protection(enable)
      if !enable
        self.accessible_attributes = nil
      elsif accessible_attributes.nil?
        self.accessible_attributes = Set.new
      end
    end

    # Specifies the given attribute(s) as accessible. This automatically turns
    # on attribute protection for this model. This configuration is inherited to
    # model inheriting from it.
    def attr_accessible(*attributes)
      attr_protection true
      self.accessible_attributes += attributes.map(&:to_sym)
    end

    # Specifies the given attribute(s) as protected. This automatically turns on
    # attribute protection for this model. This configuration is inherited
    # to models inheriting from it.
    def attr_protected(*attributes)
      attr_protection true
      self.accessible_attributes -= attributes.map(&:to_sym)
    end
  end
end
