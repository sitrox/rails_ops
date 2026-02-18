require 'test_helper'

class RailsOps::Mixins::PoliciesTest < ActiveSupport::TestCase
  include TestHelper

  def test_basic_policies
    op = Class.new(RailsOps::Operation) do
      attr_reader :sequence

      policy do
        @sequence << :default
      end

      policy :on_init do
        @sequence = []
        @sequence << :on_init
      end

      policy :before_perform do
        @sequence << :before_perform
      end

      policy :after_perform do
        @sequence << :after_perform
      end

      def perform
        @sequence << :perform
      end
    end

    assert_equal %i[on_init default before_perform perform after_perform],
                 op.run!.sequence
  end

  def test_basic_policies_with_model
    group = Group.create!

    op = Class.new(RailsOps::Operation::Model::Update) do
      attr_reader :sequence

      model Group

      policy do
        @sequence << :default
      end

      policy :before_attr_assign do
        @sequence = []
        @sequence << :before_attr_assign
      end

      policy :on_init do
        @sequence << :on_init
      end

      policy :before_perform do
        @sequence << :before_perform
      end

      policy :after_perform do
        @sequence << :after_perform
      end

      def perform
        @sequence << :perform
      end
    end

    assert_equal %i[before_attr_assign on_init default before_perform perform after_perform],
                 op.run!(id: group.id).sequence
  end

  def test_before_attr_assign_needs_build_model
    # When trying to use the `:before_attr_assign` chain, we need
    # to have the `assign_attributes` method implemented, which usually
    # is implemented in the `RailsOps::Operation::Model` base class
    # and runs the `before_attr_assign` policy chain.
    assert_raises RuntimeError, match: /Policy :before_attr_assign may not be used unless your operation defines the `assign_attributes` method!/ do
      Class.new(RailsOps::Operation) do
        policy :before_attr_assign do
          # Nothing needed here
        end
      end
    end
  end

  def test_before_model_validation_sequence
    group = Group.create!

    op = Class.new(RailsOps::Operation::Model::Update) do
      attr_reader :sequence

      model Group

      policy :before_attr_assign do
        @sequence = []
      end

      policy :before_nested_model_ops do
        @sequence << :before_nested_model_ops
      end

      policy :before_model_validation do
        @sequence << :before_model_validation
      end

      policy :before_model_save do
        @sequence << :before_model_save
      end

      def perform
        @sequence << :before_save
        save!
        @sequence << :after_save
      end
    end

    result = op.run!(id: group.id)
    assert_equal %i[
      before_save
      before_nested_model_ops
      before_model_validation
      before_model_save
      after_save
    ], result.sequence
  end

  def test_before_model_validation_needs_build_model
    assert_raises RuntimeError, match: /Policy :before_model_validation may not be used unless your operation defines the `build_model` method!/ do
      Class.new(RailsOps::Operation) do
        policy :before_model_validation do
          # Nothing needed here
        end
      end
    end
  end

  def test_before_model_validation_attribute_sanitization
    op = Class.new(RailsOps::Operation::Model::Create) do
      model Group

      policy :before_model_validation do
        # Simulate role-dependent attribute cleanup: nil out color
        # when name is "restricted".
        model.color = nil if model.name == 'restricted'
      end
    end

    # With name "restricted", the policy should nil out color before
    # validation runs.
    result = op.run!(group: { name: 'restricted', color: 'red' })
    assert_equal 'restricted', result.model.name
    assert_nil result.model.color

    # With a different name, color should be preserved.
    result = op.run!(group: { name: 'normal', color: 'blue' })
    assert_equal 'normal', result.model.name
    assert_equal 'blue', result.model.color
  end

  def test_before_model_validation_runs_before_validation
    # Add a validation to Group that rejects color "invalid", then
    # use a before_model_validation policy to fix it before validate!
    # runs. If the policy runs at the right time, the operation
    # succeeds.
    op = Class.new(RailsOps::Operation::Model::Create) do
      model Group do
        validates :color, exclusion: { in: ['invalid'] }
      end

      policy :before_model_validation do
        model.color = 'fixed' if model.color == 'invalid'
      end
    end

    result = op.run!(group: { name: 'test', color: 'invalid' })
    assert_equal 'fixed', result.model.color
  end

  def test_prepend_action
    op = Class.new(RailsOps::Operation) do
      attr_reader :sequence

      policy :on_init do
        @sequence = []
      end

      policy :before_perform do
        @sequence << :before_perform_2
      end

      policy :before_perform, prepend_action: true do
        @sequence << :before_perform_1
      end

      def perform; end
    end

    assert_equal %i[before_perform_1 before_perform_2],
                 op.run!.sequence
  end
end
