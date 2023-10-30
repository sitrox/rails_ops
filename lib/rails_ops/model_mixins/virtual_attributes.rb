module RailsOps::ModelMixins::VirtualAttributes
  extend ActiveSupport::Concern

  included do
    include ActiveType::VirtualAttributes
  end

  # rubocop: disable Naming/PredicateName
  # TODO: Document this. Why is this necessary and not part of ActiveType?
  def has_attribute?(name)
    return true if self.class._has_virtual_column?(name)
    return super
  end
  # rubocop: enable Naming/PredicateName

  # TODO: Document this. Why is this necessary and not part of ActiveType?
  def column_for_attribute(name)
    if self.class._has_virtual_column?(name)
      return VirtualColumnWrapper.new(singleton_class._virtual_column(name))
    else
      super
    end
  end
end
