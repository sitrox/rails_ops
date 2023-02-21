require 'test_helper'
require 'rails_ops/authorization_backend/can_can_can'
require 'cancancan'

class RailsOps::Operation::UpdateLazyAuthTest < ActiveSupport::TestCase
  include TestHelper

  BASIC_OP = Class.new(RailsOps::Operation::Model::Update) do
    model ::Group

    model_authorization_action :update, lazy: true

    def perform
      fail osparams.exception if osparams.exception
      @done = true
    end
  end

  ABILITY = Class.new do
    include CanCan::Ability

    def initialize(read: false, update: false)
      super()
      can :read, Group if read
      can :update, Group if update
    end
  end

  setup do
    Group.delete_all
    Group.create!(id: 1, name: 'Group')
    RailsOps.config.authorization_backend = 'RailsOps::AuthorizationBackend::CanCanCan'
  end

  def test_unpermitted_read
    ctx = RailsOps::Context.new(ability: ABILITY.new)
    assert_raises CanCan::AccessDenied do
      BASIC_OP.new(ctx, id: 1)
    end
  end

  def test_permitted_read
    ctx = RailsOps::Context.new(ability: ABILITY.new(read: true))
    assert_nothing_raised do
      BASIC_OP.new(ctx, id: 1)
    end
  end

  def test_unpermitted_update
    ctx = RailsOps::Context.new(ability: ABILITY.new(read: true))
    op = BASIC_OP.new(ctx, id: 1)
    assert_raises CanCan::AccessDenied do
      op.run!
    end
  end

  def test_permitted_update
    ctx = RailsOps::Context.new(ability: ABILITY.new(read: true, update: true))
    op = BASIC_OP.new(ctx, id: 1)
    assert_nothing_raised do
      op.run!
    end
  end
end
