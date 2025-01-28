require 'test_helper'
require 'rails_ops/authorization_backend/can_can_can'

class RailsOps::Operation::Model::UpdateTest < ActiveSupport::TestCase
  include TestHelper

  BASIC_OP = Class.new(RailsOps::Operation::Model::Update) do
    model Group
  end

  FLOWER_OP = Class.new(RailsOps::Operation::Model::Update) do
    model Flower do
      attribute :color

      def optimal_bpm
        174
      end
    end
  end

  SECOND_FLOWER_OP = Class.new(RailsOps::Operation::Model::Update) do
    model Flower do
      validate :planted_is_true
      before_update :do_calculation

      def response_to_everything
        42
      end

      def planted_is_true
        errors.add(:planted, 'Needs to be true') unless planted?
      end

      def do_calculation
        1 + 1
      end
    end
  end

  def test_basic
    g = Group.create
    op = BASIC_OP.new(id: g.id)
    assert_equal g.id, op.model.id
    assert op.model.class < Group
  end

  def test_parent_op
    g = Group.create
    op = BASIC_OP.new(id: g.id)
    assert_equal op, op.model.parent_op
  end

  def test_issue_59992
    flower1 = Flower.create!(planted: true)
    flower2 = Flower.create!(planted: false)

    op = FLOWER_OP.new(id: flower1.id)

    assert op.model.respond_to?(:color)
    assert op.model.is_a?(FLOWER_OP.model)

    op.model.color = :red

    assert_equal :red, op.model.color

    assert_raises ActiveRecord::RecordNotFound do
      FLOWER_OP.new(id: flower2.id)
    end
  end

  def test_validation
    flower = Flower.create!(planted: true)
    assert flower.planted

    # This works fine
    op1 = SECOND_FLOWER_OP.run!(id: flower.id, flower: { planted: true })
    assert_equal 42, op1.model.response_to_everything
    assert op1.model.respond_to?(:response_to_everything)
    assert op1.model.respond_to?(:planted_is_true)
    refute op1.model.respond_to?(:optimal_bpm)

    # This fails in Rails 7 and ruby 3.1.0, as the validation seems to be triggered
    # in this as well, even though the validation is not defined here
    # More interesting, it seems that only the validation and the before_update
    # are handled incorrectly, the other methods work fine
    op2 = FLOWER_OP.run!(id: flower.id, flower: { planted: true })
    assert_equal 174, op2.model.optimal_bpm
    assert op2.model.respond_to?(:optimal_bpm)
    refute op2.model.respond_to?(:planted_is_true)
    refute op2.model.respond_to?(:response_to_everything)
  end

  def test_load_authorization_order
    RailsOps.config.authorization_backend = 'RailsOps::AuthorizationBackend::CanCanCan'

    op_klass = Class.new(RailsOps::Operation::Model::Update) do
      model ::Group
    end

    ability = Class.new do
      include CanCan::Ability

      def initialize
        super
        can :read, Group, color: 'red'
        can :update, Group, color: 'red'
      end
    end.new

    context = RailsOps::Context.new(ability: ability)

    assert_nothing_raised do
      model = Group.create!(color: 'red')
      op_klass.run!(context, id: model.id, group: { color: 'red' })
    end

    assert_raises CanCan::AccessDenied do
      model = Group.create!(color: 'blue')
      op_klass.run!(context, id: model.id, group: { color: 'red' })
    end

    assert_nothing_raised do
      model = Group.create!(color: 'red')
      op_klass.run!(context, id: model.id, group: { color: 'blue' })
    end
  ensure
    RailsOps.config.authorization_backend = nil
  end

  def test_update_authorization_order
    RailsOps.config.authorization_backend = 'RailsOps::AuthorizationBackend::CanCanCan'

    op_klass = Class.new(RailsOps::Operation::Model::Update) do
      model ::Group
    end

    ability = Class.new do
      include CanCan::Ability

      def initialize
        super
        can :read, Group
        can :update, Group, color: 'red'
      end
    end.new

    context = RailsOps::Context.new(ability: ability)

    assert_nothing_raised do
      model = Group.create!(color: 'red')
      op_klass.run!(context, id: model.id, group: { color: 'red' })
    end

    assert_raises CanCan::AccessDenied do
      model = Group.create!(color: 'blue')
      op_klass.run!(context, id: model.id, group: { color: 'red' })
    end

    assert_nothing_raised do
      model = Group.create!(color: 'red')
      op_klass.run!(context, id: model.id, group: { color: 'blue' })
    end
  ensure
    RailsOps.config.authorization_backend = nil
  end

  def test_policies
    op_klass = Class.new(RailsOps::Operation::Model::Update) do
      model ::Group

      policy do
        # Here, we need the model to have the new name assigned
        fail 'Attribute should be assigned to new value' unless model.name == 'new_name'

        # However, the new name should not be persisted to the database yet
        fail 'Attribute change should not be persisted yet' unless Group.find(model.id).name == 'foobar'
      end

      policy :before_attr_assign do
        # The name of the model itself should still be the initial value
        fail 'Attribute should not be assigned to new value yet' unless model.name == 'foobar'
      end

      policy :on_init do
        # Here, we need the model to have the new name assigned
        fail 'Attribute should be assigned to new value' unless model.name == 'new_name'

        # However, the new name should not be persisted to the database yet
        fail 'Attribute change should not be persisted yet' unless Group.find(model.id).name == 'foobar'
      end

      policy :before_perform do
        # Here, we need the model to have the new name assigned
        fail 'Attribute should be assigned to new value' unless model.name == 'new_name'

        # However, the new name should not be persisted to the database yet
        fail 'Attribute change should not be persisted yet' unless Group.find(model.id).name == 'foobar'
      end

      policy :after_perform do
        # Here, we need the model to have the new name assigned
        fail 'Attribute should be assigned to new value' unless model.name == 'new_name'

        # Also, the new name should be persisted to the database
        fail 'Attribute change should not be persisted yet' unless Group.find(model.id).name == 'new_name'
      end
    end

    model = Group.create!(name: 'foobar')
    assert_nothing_raised do
      op_klass.run!(id: model.id, group: { name: 'new_name' })
    end
  end
end
