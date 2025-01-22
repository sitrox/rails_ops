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

  def test_run_without_perform
    cls = Class.new(RailsOps::Operation)
    assert_nothing_raised do
      cls.new
    end
    assert_raises NotImplementedError do
      cls.run!
    end
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
    params = { a: 1, b: 1 }
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

  def test_check_performed
    op = BASIC_OP.new
    assert_raises_with_message RuntimeError, 'Operation has not yet been performed.' do
      op.check_performed!
    end
    op.run!
    assert_nothing_raised do
      op.check_performed!
    end
  end

  def test_inspect
    # See https://bugs.ruby-lang.org/issues/20433#note-10
    if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("3.4.0")
      assert_equal 'RailsOps::OperationTest::BASIC_OP ({"foo" => :bar})', BASIC_OP.new(foo: :bar).inspect
    else
      assert_equal 'RailsOps::OperationTest::BASIC_OP ({"foo"=>:bar})', BASIC_OP.new(foo: :bar).inspect
    end
  end

  def test_inspect_with_numeric_param_keys
    # See https://bugs.ruby-lang.org/issues/20433#note-10
    if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("3.4.0")
      assert_equal 'RailsOps::OperationTest::BASIC_OP ({1 => 2})', BASIC_OP.new(1 => 2).inspect
    else
      assert_equal 'RailsOps::OperationTest::BASIC_OP ({1=>2})', BASIC_OP.new(1 => 2).inspect
    end
  end

  def test_with_rollback_on_exception
    op = Class.new(RailsOps::Operation) do
      def perform
        with_rollback_on_exception do
          fail 'Rollback please'
        end
      end
    end.new
    assert_raises RailsOps::Exceptions::RollbackRequired do
      op.run
    end
  end

  def test_op_with_schema3(use_default: false)
    op = Class.new(RailsOps::Operation) do
      schema_block = proc do
        int! :id
        hsh! :hash do
          int? :number
          int! :required_number
        end
      end
      if use_default
        schema(&schema_block)
      else
        schema3(&schema_block)
      end
    end

    assert_nothing_raised do
      op.new(id: 1, hash: { required_number: 1 })
    end
    assert_raises Schemacop::Exceptions::ValidationError do
      op.new(id: 1, hash: {})
    end
  end

  def test_op_with_schema2(use_default: false)
    op = Class.new(RailsOps::Operation) do
      schema_block = proc do
        req :id, :integer
        req :hash, :hash do
          opt :number, :integer
          req :required_number, :integer
        end
      end

      if use_default
        schema(&schema_block)
      else
        schema2(&schema_block)
      end
    end

    assert_nothing_raised do
      op.new(id: 1, hash: { required_number: 1 })
    end
    assert_raises Schemacop::Exceptions::ValidationError do
      op.new(id: 1, hash: {})
    end
  end

  def test_op_with_schema_default
    RailsOps.config.default_schemacop_version = 3
    test_op_with_schema3(use_default: true)

    RailsOps.config.default_schemacop_version = 2
    test_op_with_schema2(use_default: true)

    RailsOps.config.default_schemacop_version = -50
    assert_raises_with_message RuntimeError, 'Schemacop schema versions supported are 2 and 3.' do
      test_op_with_schema3(use_default: true)
    end
    RailsOps.config.default_schemacop_version = 3
  end

  def test_require_context
    op = Class.new(RailsOps::Operation) do
      require_context :user, :session
    end

    ctx = RailsOps::Context.new(user: Class.new, session: Class.new)
    assert_raises_with_message RailsOps::Exceptions::MissingContextAttribute, 'This operation requires the context attribute :user to be present.' do
      op.new
    end
    assert_nothing_raised do
      op.new(ctx, foo: :bar)
    end
  end

  def test_run_through_context
    op = Class.new(RailsOps::Operation) do
      def perform; end
    end
    ctx = RailsOps::Context.new(user: Class.new, session: Class.new)
    assert_nothing_raised do
      ctx.run! op, foo: :bar
    end
  end
end
