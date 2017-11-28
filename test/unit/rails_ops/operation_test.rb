require 'test_helper'

class RailsOps::OperationTest < Minitest::Test
  include TestHelper

  EXCEPTION = Class.new(StandardError)

  BASIC_OP = Class.new(RailsOps::Operation) do
    attr_reader :done

    def validation_errors
      super + [EXCEPTION]
    end

    def perform
      fail osparams.exception if osparams.exception
      @done = true
    end
  end

  def test_basic_operation
    op = BASIC_OP.new
    op.run
    assert op.done
  end

  def test_static_run
    assert BASIC_OP.run
  end

  def test_static_run!
    assert BASIC_OP.run!.done
  end

  def test_non_validation_error
    assert_raises_with_message RuntimeError, 'Standard exception' do
      BASIC_OP.run(exception: 'Standard exception')
    end

    assert_raises_with_message RuntimeError, 'Standard exception' do
      BASIC_OP.run!(exception: 'Standard exception')
    end
  end

  def test_validation_errors
    assert_raises_with_message RailsOps::Exceptions::ValidationFailed, 'A message' do
      BASIC_OP.run!(exception: RailsOps::Exceptions::ValidationFailed.new('A message'))
    end

    refute BASIC_OP.run(exception: RailsOps::Exceptions::ValidationFailed.new('A message'))
  end
end
