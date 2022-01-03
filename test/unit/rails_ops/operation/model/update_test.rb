require 'test_helper'

class RailsOps::Operation::Model::UpdateTest < ActiveSupport::TestCase
  include TestHelper

  BASIC_OP = Class.new(RailsOps::Operation::Model::Update) do
    model Group
  end

  FLOWER_OP = Class.new(RailsOps::Operation::Model::Update) do
    model Flower do
      attribute :color
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
    f_1 = Flower.create!(planted: true)
    f_2 = Flower.create!(planted: false)

    op = FLOWER_OP.new(id: f_1.id)

    assert op.model.respond_to?(:color)
    assert op.model.is_a?(FLOWER_OP.model)

    op.model.color = :red

    assert_equal :red, op.model.color

    op = FLOWER_OP.new(id: f_2.id)

    assert_raises ActiveRecord::RecordNotFound do
      op.model
    end
  end
end
