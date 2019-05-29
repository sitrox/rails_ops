require 'test_helper'

class RailsOps::Mixins::Model::NestingTest < ActiveSupport::TestCase
  include TestHelper

  GROUP_CREATION_OP = Class.new RailsOps::Operation::Model::Create do
    model Group do
      validates :name, presence: true
    end
  end

  BASIC_OP = Class.new RailsOps::Operation::Model::Create do
    model User do
    end
    nest_model_op :group, GROUP_CREATION_OP
  end

  def test_has_many_basic
    BASIC_OP.run!(
      user: {
        name: 'test',
        group_attributes: {
          name: 'g1',
          color: 'blue'
        }
      }
    )

    assert_equal 1, User.count
    assert_equal 1, Group.count
    assert_equal 'test', User.first.name
    assert_equal 'g1', Group.first.name
    assert_equal Group.first, User.first.group
    assert_equal [User.first], Group.first.users
  end

  def test_has_many_validation
    op = BASIC_OP.new(
      user: {
        name: 'test',
        group_attributes: {
          color: 'blue'
        }
      }
    )

    assert_raises ActiveRecord::RecordInvalid do
      op.run!
    end

    refute op.model.persisted?
    refute op.model.group.persisted?

    assert_equal BASIC_OP.model, op.model.class
    assert_equal GROUP_CREATION_OP.model, op.model.group.class

    refute op.model.group.valid?
    refute op.model.valid?
  end
end
