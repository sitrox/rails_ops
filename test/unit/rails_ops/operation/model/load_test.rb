require 'test_helper'

class RailsOps::Operation::Model::LoadTest < ActiveSupport::TestCase
  include TestHelper

  BASIC_OP = Class.new(RailsOps::Operation::Model::Load) do
    model Group
  end

  def test_basic
    g = Group.create
    op = BASIC_OP.new(id: g.id)
    assert_equal g, op.model
    assert_equal Group, op.model.class
  end

  def test_parent_op
    g = Group.create
    cls = Class.new(RailsOps::Operation::Model::Load) do
      model Group do
        # Nothing do do
      end
    end
    op = cls.new(id: g.id)
    assert_equal op, op.model.parent_op
  end

  def test_without_id
    assert_raises_with_message RuntimeError, 'Param :id must be given.' do
      BASIC_OP.new
    end
  end

  def test_not_found
    assert_raise ActiveRecord::RecordNotFound do
      BASIC_OP.new(id: 5)
    end
  end

  def test_other_model_id_field
    cls = Class.new(RailsOps::Operation::Model::Load) do
      model Group

      def model_id_field
        :name
      end
    end

    g = Group.create(name: 'g1')
    assert_equal g, cls.new(name: 'g1').model
  end

  def test_too_many_authorization_actions
    assert_raises_with_message ArgumentError, 'Too many arguments' do
      Class.new(RailsOps::Operation::Model::Load) do
        model Group
        load_model_authorization_action :read, :update
      end
    end
  end

  def test_model_authorization_action_not_permitted
    assert_raises_with_message RuntimeError, /Use `load_model_authorization_action` instead/ do
      Class.new(RailsOps::Operation::Model::Load) do
        model Group
        model_authorization_action :read, :update
      end
    end
  end

  def test_find_model_relation_default
    g = Group.create(name: 'default')
    op = BASIC_OP.new(id: g.id)
    assert_equal g, op.model
  end

  def test_find_model_relation_with_where
    g1 = Group.create(name: 'visible')
    g2 = Group.create(name: 'hidden')

    cls = Class.new(RailsOps::Operation::Model::Load) do
      model Group

      protected

      def find_model_relation
        Group.where(name: 'visible')
      end
    end

    assert_equal g1, cls.new(id: g1.id).model

    assert_raise ActiveRecord::RecordNotFound do
      cls.new(id: g2.id)
    end
  end

  def test_find_model_relation_with_joins
    g1 = Group.create(name: 'with_users')
    g2 = Group.create(name: 'empty')
    User.create(name: 'Alice', group: g1)

    cls = Class.new(RailsOps::Operation::Model::Load) do
      model Group

      protected

      def find_model_relation
        Group.joins(:users).where(users: { name: 'Alice' })
      end
    end

    assert_equal g1, cls.new(id: g1.id).model

    assert_raise ActiveRecord::RecordNotFound do
      cls.new(id: g2.id)
    end
  end

  def test_find_model_relation_preserves_model_extensions
    g = Group.create(name: 'test')

    cls = Class.new(RailsOps::Operation::Model::Load) do
      model Group do
        def custom_method
          'extended'
        end
      end

      protected

      def find_model_relation
        Group.where(name: 'test')
      end
    end

    op = cls.new(id: g.id)
    assert_equal 'extended', op.model.custom_method
    assert op.model.class < Group
    assert_not_equal Group, op.model.class
  end
end
