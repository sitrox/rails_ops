require 'test_helper'

class RailsOps::OperationTest < ActiveSupport::TestCase
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

  def test_run
    assert BASIC_OP.new.run
  end

  def test_run!
    assert BASIC_OP.new.run!.done
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

  def test_constructor
    context = RailsOps::Context.new

    # new()
    op = BASIC_OP.new
    assert_not_equal context.object_id, op.context.object_id
    assert_equal({}, op.params)

    # new(nil)
    op = BASIC_OP.new(nil)
    assert_not_equal context.object_id, op.context.object_id
    assert_equal({}, op.params)

    # new(nil, nil)
    op = BASIC_OP.new(nil)
    assert_not_equal context.object_id, op.context.object_id
    assert_equal({}, op.params)

    # new(context, params)
    op = BASIC_OP.new(context, key: :val)
    assert_equal context.object_id, op.context.object_id
    assert_equal({ key: :val }.with_indifferent_access, op.params)

    # new(context)
    op = BASIC_OP.new(context)
    assert_equal context.object_id, op.context.object_id
    assert_equal({}, op.params)

    # new(params)
    op = BASIC_OP.new(key: :val)
    assert_not_equal context.object_id, op.context.object_id
    assert_equal({ key: :val }.with_indifferent_access, op.params)

    # new(params) with ActionController::Parameters
    params = ActionController::Parameters.new(key: :val)
    op = BASIC_OP.new(params)
    assert_not_equal params.object_id, op.params.object_id
    assert_equal({ key: :val }.with_indifferent_access, op.params)
  end

  def test_params
    params = { a: 1, 'b': 1 }
    op = BASIC_OP.new(params)

    # ---------------------------------------------------------------
    # Check if op.params and op.osparams are correctly populated
    # ---------------------------------------------------------------
    assert_equal params.with_indifferent_access, op.params
    assert_equal op.params, op.osparams.to_h.with_indifferent_access

    # ---------------------------------------------------------------
    # Verify that operations work with a duplicate params hash,
    # and op.params and op.osparams are not connected
    # ---------------------------------------------------------------

    # Change of outside params hash
    params[:a] = 2
    assert_equal 1, op.params[:a]
    assert_equal 1, op.osparams[:a]

    # Change of op.params hash
    op.params[:a] = 3
    assert_equal 2, params[:a]
    assert_equal 1, op.osparams[:a]

    # Change of op.osparams hash
    op.osparams.a = 4
    assert_equal 2, params[:a]
    assert_equal 3, op.params[:a]

    # ---------------------------------------------------------------
    # Verify that the params hash is deep duplicated
    # ---------------------------------------------------------------
    params = { a: { foo: :bar } }
    op = Class.new(RailsOps::Operation).new(params)
    params[:a][:foo] = :baz

    assert_equal :bar, op.params[:a][:foo]
    assert_equal :bar, op.osparams.a[:foo]
  end

  def test_performed
    op = BASIC_OP.new
    refute op.performed?
    op.run!
    assert op.performed?
  end

  def test_inspect
    assert_equal 'RailsOps::OperationTest::BASIC_OP ({"foo"=>:bar})',
                 BASIC_OP.new(foo: :bar).inspect
  end
end
