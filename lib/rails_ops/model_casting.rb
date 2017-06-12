module RailsOps::ModelCasting
  def self.cast(model)
    if model.class.respond_to?(:extended_record_base_class)
      return ActiveType.cast(model, model.class.extended_record_base_class)
    else
      return model
    end
  end

  def self.original_class_for(model_class)
    if model_class.respond_to?(:extended_record_base_class)
      return model_class.extended_record_base_class
    else
      return model_class
    end
  end
end
