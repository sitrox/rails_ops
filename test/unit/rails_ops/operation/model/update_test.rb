require 'test_helper'

class RailsOps::Operation::Model::UpdateTest < ActiveSupport::TestCase
  include TestHelper

  BASIC_OP = Class.new(RailsOps::Operation::Model::Update) do
    model Group
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
end
