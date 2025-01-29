require 'test_helper'

class RailsOps::Operation::Model::CreateTest < ActiveSupport::TestCase
  include TestHelper

  BASIC_OP = Class.new(RailsOps::Operation::Model::Create) do
    model Group
  end

  ATTR_OP = Class.new(RailsOps::Operation::Model::Create) do
    model ::Group do
      attribute :long_group_name
    end
  end

  def test_attribute
    op = ATTR_OP.run!(group: { name: 'Test', color: 'red', long_group_name: 'Testgroup for extended testing' })

    assert_equal 'Test', op.model.name
    assert_equal 'red', op.model.color
    assert_equal 'Testgroup for extended testing', op.model.long_group_name
    assert op.model.persisted?
    refute op.model.changed?
  end

  def test_basic
    op = BASIC_OP.run!(group: { name: 'test', color: 'red' })

    assert_equal 'test', op.model.name
    assert_equal 'red', op.model.color
    assert op.model.persisted?
    refute op.model.changed?
  end

  def test_model_extension
    cls = Class.new(RailsOps::Operation::Model::Create) do
      model Group do
        validates :color, presence: true
      end
    end

    assert cls.new.model.class < Group

    assert_raises ActiveRecord::RecordInvalid do
      cls.run!(group: { name: 'test' })
    end
  end

  def test_parent_op
    op = BASIC_OP.new
    assert_equal op, op.model.parent_op
  end

  def test_always_extend_model_class
    assert RailsOps::Operation::Model::Create.always_extend_model_class?
  end

  def test_build
    op = BASIC_OP.new
    op.build_model

    assert op.instance_variable_get(:@model)

    assert_raises_with_message RuntimeError, 'Model can only be built once.' do
      op.build_model
    end
  end

  def test_policies
    op_klass = Class.new(RailsOps::Operation::Model::Create) do
      model ::Group

      policy do
        # Here, we need the model to have the new name assigned
        fail 'Attribute should be assigned to new value' unless model.name == 'new_name'

        # However, the model should not be persisted yet
        fail 'Model should not be persisted to the database yet' if model.persisted?
      end

      policy :before_attr_assign do
        # The name of the model itself should still be nil
        fail 'Attribute should not be assigned to a value yet' if model.name.present?
      end

      policy :on_init do
        # Here, we need the model to have the new name assigned
        fail 'Attribute should be assigned to new value' unless model.name == 'new_name'

        # However, the model should not be persisted yet
        fail 'Model should not be persisted to the database yet' if model.persisted?
      end

      policy :before_perform do
        # Here, we need the model to have the new name assigned
        fail 'Attribute should be assigned to new value' unless model.name == 'new_name'

        # However, the model should not be persisted yet
        fail 'Model should not be persisted to the database yet' if model.persisted?
      end

      policy :after_perform do
        # Here, we need the model to have the new name assigned
        fail 'Attribute should be assigned to new value' unless model.name == 'new_name'

        # Now, the model should be persisted to the database
        fail 'Model should not be persisted to the database yet' unless model.persisted?
      end
    end

    assert_nothing_raised do
      op_klass.run!(group: { name: 'new_name' })
    end
  end
end
