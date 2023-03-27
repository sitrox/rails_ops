require 'test_helper'
require 'rails_ops/authorization_backend/can_can_can'
require 'cancancan'

class RailsOps::Operation::AuthTest < ActiveSupport::TestCase
  include TestHelper

  LOAD_OP = Class.new(RailsOps::Operation::Model::Load) do
    model ::Group
  end

  LOAD_OP_WITHOUT_AUTH = Class.new(RailsOps::Operation::Model::Load) do
    model ::Group
    without_authorization
  end

  UPDATE_OP = Class.new(RailsOps::Operation::Model::Update) do
    model ::Group
  end

  CREATE_OP = Class.new(RailsOps::Operation::Model::Create) do
    model ::Group
  end

  DESTROY_OP = Class.new(RailsOps::Operation::Model::Destroy) do
    model ::Group
  end

  ABILITY = Class.new do
    include CanCan::Ability

    def initialize(read: false, update: false, create: false, destroy: false)
      super()

      can :read, Group if read
      can :update, Group if update
      can :create, Group if create
      can :destroy, Group if destroy
    end
  end

  setup do
    Group.create!(id: 1, name: 'Group')
    RailsOps.config.authorization_backend = 'RailsOps::AuthorizationBackend::CanCanCan'
  end

  def test_unpermitted_read
    ctx = RailsOps::Context.new(ability: ABILITY.new)
    assert_raises CanCan::AccessDenied do
      LOAD_OP.new(ctx, id: 1)
    end
  end

  def test_unpermitted_read_without_auth
    ctx = RailsOps::Context.new(ability: ABILITY.new)
    assert_nothing_raised do
      LOAD_OP_WITHOUT_AUTH.new(ctx, id: 1)
    end
  end

  def test_permitted_read
    ctx = RailsOps::Context.new(ability: ABILITY.new(read: true))
    assert_nothing_raised do
      res = LOAD_OP.new(ctx, id: 1)
      assert_equal 'Group', res.model.name
    end
  end

  def test_unpermitted_update
    ctx = RailsOps::Context.new(ability: ABILITY.new(read: true))
    assert_raises CanCan::AccessDenied do
      op = UPDATE_OP.new(ctx, id: 1, group: { name: 'Group2' })
      res = op.run!
      assert_equal 'Group', res.model.name
    end
  end

  def test_permitted_update
    ctx = RailsOps::Context.new(ability: ABILITY.new(read: true, update: true))
    assert_nothing_raised do
      op = UPDATE_OP.new(ctx, id: 1, group: { name: 'Group2' })
      res = op.run!
      assert_equal 'Group2', res.model.name
    end
  end

  def test_unpermitted_create
    ctx = RailsOps::Context.new(ability: ABILITY.new(read: true))
    assert_raises CanCan::AccessDenied do
      op = CREATE_OP.new(ctx, id: 2, group: { name: 'Group2' })
      op.run!
    end
  end

  def test_permitted_create
    ctx = RailsOps::Context.new(ability: ABILITY.new(read: true, create: true))
    assert_nothing_raised do
      op = CREATE_OP.new(ctx, id: 2, group: { name: 'Group2' })
      op.run!
      res = LOAD_OP.new(id: 2)
      assert_equal 'Group2', res.model.name
    end
  end

  def test_unpermitted_destroy
    ctx = RailsOps::Context.new(ability: ABILITY.new(read: true))
    assert_raises CanCan::AccessDenied do
      op = DESTROY_OP.new(ctx, id: 1)
      op.run!
    end
  end

  def test_permitted_destroy
    ctx = RailsOps::Context.new(ability: ABILITY.new(read: true, destroy: true))
    assert_nothing_raised do
      op = DESTROY_OP.new(ctx, id: 1)
      op.run!
    end
  end
end
