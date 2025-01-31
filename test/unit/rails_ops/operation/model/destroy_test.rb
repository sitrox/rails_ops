class RailsOps::Operation::Model::DestroyTest < ActiveSupport::TestCase
  include TestHelper

  BASIC_OP = Class.new(RailsOps::Operation::Model::Destroy) do
    model Group
  end

  def test_basic
    g = Group.create
    op = BASIC_OP.new(id: g.id)
    assert_equal g, op.model
    assert_equal Group, op.model.class
    op.run!
    assert op.model.destroyed?
  end

  def test_not_deletable
    g = Group.create
    cls = Class.new(RailsOps::Operation::Model::Destroy) do
      model Group, 'NotDeletableGroup' do
        def deleteable?
          false
        end
      end
    end
    op = cls.new(id: g.id)
    assert_raises RailsOps::Exceptions::ModelNotDeleteable do
      op.run!
    end
  end

  def test_model_authorization_action_permitted
    assert_nothing_raised do
      Class.new(RailsOps::Operation::Model::Destroy) do
        model Group
        load_model_authorization_action :foobar
        model_authorization_action :barfoo
      end
    end
  end
end
