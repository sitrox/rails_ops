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
