require 'test_helper'
require 'rails_ops/authorization_backend/can_can_can'
require 'cancancan'

class RailsOps::Mixins::ParamAuthorizationTest < ActiveSupport::TestCase
  include TestHelper

  class Ability
    include CanCan::Ability

    def initialize(foo: false, bar: false, baz: false)
      can :read, Group
      can :foo, Group if foo
      can :bar, Group if bar
      can :baz, Group if baz
    end
  end

  setup do
    RailsOps.config.authorization_backend = 'RailsOps::AuthorizationBackend::CanCanCan'

    Group.create!(id: 1, name: 'My Group')

    @op = Class.new(RailsOps::Operation::Model::Load) do
      schema3 do
        int! :id
        str? :foo
        hsh? :bar do
          str? :baz
        end
      end

      model ::Group

      authorize_param %i[foo], :foo, :subject_1
      authorize_param %i[bar], :bar, :subject_1
      authorize_param %i[bar baz], :baz, :subject_1

      def perform
        # Do nothing
      end
    end
  end

  def test_without_array
    @op = Class.new(RailsOps::Operation::Model::Load) do
      schema3 do
        int! :id
        str? :foo
        hsh? :bar do
          str? :baz
        end
      end

      model ::Group

      authorize_param :foo, :foo, :subject_1
      authorize_param :bar, :bar, :subject_1

      def perform
        # Do nothing
      end
    end

    ctx = RailsOps::Context.new(ability: Ability.new)

    assert_raises CanCan::AccessDenied do
      @op.run!(ctx, id: 1, foo: 'bar')
    end

    assert_raises CanCan::AccessDenied do
      @op.run!(ctx, id: 1, bar: {})
    end

    assert_raises CanCan::AccessDenied do
      @op.run!(ctx, id: 1, bar: { baz: 'baz' })
    end
  end

  def test_without_ability
    @op.run!(id: 1)
  end

  def test_no_authorized_params
    ctx = RailsOps::Context.new(ability: Ability.new)
    assert_nothing_raised do
      @op.run!(ctx, id: 1)
    end
  end

  def test_fail
    ctx = RailsOps::Context.new(ability: Ability.new)

    assert_raises CanCan::AccessDenied do
      @op.run!(ctx, id: 1, foo: 'bar')
    end

    assert_raises CanCan::AccessDenied do
      @op.run!(ctx, id: 1, bar: {})
    end

    assert_raises CanCan::AccessDenied do
      @op.run!(ctx, id: 1, bar: { baz: 'baz' })
    end
  end

  def test_success
    ctx = RailsOps::Context.new(ability: Ability.new(foo: true, bar: true, baz: true))

    assert_nothing_raised do
      @op.run!(ctx, id: 1, foo: 'foo', bar: { baz: 'baz' })
    end
  end
end
