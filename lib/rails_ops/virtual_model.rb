class RailsOps::VirtualModel < ActiveType::Object
  include RailsOps::ModelMixins

  # Override write_attribute. This enables using write_attribute even for
  # virtual attributes.
  def write_attribute(name, value)
    if virtual_columns_hash.include?(name.to_s)
      write_virtual_attribute(name, value)
    else
      super
    end
  end
end
