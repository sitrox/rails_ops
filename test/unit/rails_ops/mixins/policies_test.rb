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
