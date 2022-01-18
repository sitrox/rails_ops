class RailsOps::ModelMixins::VirtualAttributes::VirtualColumnWrapper
  def initialize(virtual_column)
    @virtual_column = virtual_column
  end

  def type
    @virtual_column.instance_variable_get(:@type_caster).instance_variable_get(:@type)
  end

  def default_function
    nil
  end
end
