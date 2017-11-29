require 'test_helper'

class RailsOps::Operation::ModelTest < ActiveSupport::TestCase
  include TestHelper

  def test_always_extend_model_class_true
    cls = Class.new(RailsOps::Operation::Model) do
      def self.always_extend_model_class?
        true
      end

      model Group
    end

    refute_equal Group, cls.model
  end

  def test_always_extend_model_class_false
    cls = Class.new(RailsOps::Operation::Model) do
      def self.always_extend_model_class?
        false
      end

      model Group
    end

    assert_equal Group, cls.model
  end

  def test_model_mixins
    cls = Class.new(RailsOps::Operation::Model) do
      def self.always_extend_model_class?
        true
      end

      model Group
    end

    assert cls.model.included_modules.include?(RailsOps::ModelMixins)
  end

  def test_virtual_model_name
    cls = Class.new(RailsOps::Operation::Model) do
      model RailsOps::VirtualModel, 'Example'
    end

    assert_equal 'Example', cls.model.virtual_model_name
  end

  def test_default_model_class
    cls = Class.new(RailsOps::Operation::Model) do
      model do
        attribute :name, :string
      end
    end

    assert cls.model < ActiveType::Object
  end

  def test_no_model_class
    assert_raises_with_message RuntimeError, 'No model class has been set.' do
      Class.new(RailsOps::Operation::Model) do
        model
      end
    end
  end
end
