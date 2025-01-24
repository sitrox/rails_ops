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
      save!
      @done = true
    end
  end

  ABILITY = Class.new do
    include CanCan::Ability

    def initialize(read: false, update: false)
      super()
      can :read, Group, color: %w[red green] if read
      can :update, Group, color: 'red' if update
    end
  end

  setup do
    Group.delete_all
    Group.create!(id: 1, name: 'Red Group', color: 'red')
    Group.create!(id: 2, name: 'Blue group', color: 'blue')
    Group.create!(id: 3, name: 'Green group', color: 'green')
    RailsOps.config.authorization_backend = 'RailsOps::AuthorizationBackend::CanCanCan'
  end

  def test_unpermitted_read_permitted_color
    ctx = RailsOps::Context.new(ability: ABILITY.new)
    assert_raises CanCan::AccessDenied do
      BASIC_OP.new(ctx, id: 1)
    end
  end

  def test_unpermitted_read_unpermitted_color
    ctx = RailsOps::Context.new(ability: ABILITY.new)
    assert_raises CanCan::AccessDenied do
      BASIC_OP.new(ctx, id: 2)
    end
  end

  def test_permitted_read_permitted_color
    ctx = RailsOps::Context.new(ability: ABILITY.new(read: true))
    assert_nothing_raised do
      BASIC_OP.new(ctx, id: 1)
    end
  end

  def test_permitted_read_unpermitted_color
    ctx = RailsOps::Context.new(ability: ABILITY.new(read: true))
    assert_raises CanCan::AccessDenied do
      BASIC_OP.new(ctx, id: 2)
    end
  end

  def test_unpermitted_update_permitted_color
    ctx = RailsOps::Context.new(ability: ABILITY.new(read: true))
    op = BASIC_OP.new(ctx, id: 1)
    assert_raises CanCan::AccessDenied do
      op.run!
    end
  end

  def test_unpermitted_update_unpermitted_color
    ctx = RailsOps::Context.new(ability: ABILITY.new(read: true))
    op = BASIC_OP.new(ctx, id: 1)
    assert_raises CanCan::AccessDenied do
      op.run!
    end
  end

  def test_permitted_update_permitted_color
    ctx = RailsOps::Context.new(ability: ABILITY.new(read: true, update: true))
    op = BASIC_OP.new(ctx, id: 1)
    assert_nothing_raised do
      op.run!
    end
  end

  def test_permitted_update_unpermitted_color
    ctx = RailsOps::Context.new(ability: ABILITY.new(read: true, update: true))
    op = BASIC_OP.new(ctx, id: 3)
    assert_raises CanCan::AccessDenied do
      op.run!
    end
  end

  def test_permitted_update_permitted_color_other_color_target_state
    # Here, we test that we can update a record where the ability
    # allows us the `:update` action on the current state of the model,
    # despite bringing the object to a state where we won't have the
    # ability to update the object anymore afterwards.
    ctx = RailsOps::Context.new(ability: ABILITY.new(read: true, update: true))
    op = BASIC_OP.new(ctx, id: 1, group: { color: 'blue' })
    assert_nothing_raised do
      op.run!
    end
  end
end
