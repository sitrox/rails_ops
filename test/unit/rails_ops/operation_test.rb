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
    if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('3.4.0')
      assert_equal 'RailsOps::OperationTest::BASIC_OP ({"foo" => :bar})', BASIC_OP.new(foo: :bar).inspect
    else
      assert_equal 'RailsOps::OperationTest::BASIC_OP ({"foo"=>:bar})', BASIC_OP.new(foo: :bar).inspect
    end
  end

  def test_inspect_with_numeric_param_keys
    # See https://bugs.ruby-lang.org/issues/20433#note-10
    if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('3.4.0')
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
    RailsOps.deprecator.silence do
      assert_raises RailsOps::Exceptions::RollbackRequired do
        op.run
      end
    end
  end

  def test_with_rollback_on_exception_emits_deprecation_warning
    # Use a fresh call site to bypass the per-process deduplication cache
    # used by `with_rollback_on_exception`.
    op = Class.new(RailsOps::Operation) do
      class_eval(<<~RUBY, __FILE__, __LINE__ + 1)
        def perform
          with_rollback_on_exception do
            # No-op; we only care about the deprecation warning being
            # emitted on entry.
          end
        end
      RUBY
    end.new

    messages = []
    previous_behavior = RailsOps.deprecator.behavior
    RailsOps.deprecator.behavior = ->(msg, _callstack, _name, _gem) { messages << msg }
    begin
      op.run
    ensure
      RailsOps.deprecator.behavior = previous_behavior
    end

    assert_match(/with_rollback_on_exception.*deprecated/, messages.join("\n"))
  end

  def test_with_rollback_on_exception_deduplicates_per_call_site
    op = Class.new(RailsOps::Operation) do
      class_eval(<<~RUBY, __FILE__, __LINE__ + 1)
        def perform
          with_rollback_on_exception do
            # No-op
          end
        end
      RUBY
    end

    messages = []
    previous_behavior = RailsOps.deprecator.behavior
    RailsOps.deprecator.behavior = ->(msg, _callstack, _name, _gem) { messages << msg }
    begin
      op.new.run
      op.new.run
      op.new.run
    ensure
      RailsOps.deprecator.behavior = previous_behavior
    end

    assert_equal 1, messages.size, 'expected the warning to fire once per call site'
  end

  # When `run` is called inside an outer transaction and the operation does a
  # save followed by a validation error, the save must be rolled back even
  # though `run` swallows the error and returns `false`. Without the savepoint
  # wrapping inside `run`, the partial write would leak into the outer
  # transaction.
  def test_run_rolls_back_partial_writes_when_inside_outer_transaction
    op_class = Class.new(RailsOps::Operation::Model::Create) do
      model Group

      def perform
        super
        fail RailsOps::Exceptions::ValidationFailed, 'post-save check failed'
      end
    end

    ActiveRecord::Base.transaction do
      count_before = Group.count
      refute op_class.run(group: { name: 'partial', color: 'red' })
      assert_equal count_before, Group.count, 'expected save to be rolled back'
    end
  end

  # `run!` keeps its existing behavior: validation errors propagate, the
  # savepoint logic in `run` is not on the call path.
  def test_run_bang_still_raises_inside_transaction
    op_class = Class.new(RailsOps::Operation::Model::Create) do
      model Group

      def perform
        super
        fail RailsOps::Exceptions::ValidationFailed, 'post-save check failed'
      end
    end

    assert_raises RailsOps::Exceptions::ValidationFailed do
      ActiveRecord::Base.transaction do
        op_class.run!(group: { name: 'partial', color: 'red' })
      end
    end
  end

  # Successful `run` calls inside a transaction still commit the model save.
  def test_run_persists_model_on_success_inside_transaction
    op_class = Class.new(RailsOps::Operation::Model::Create) do
      model Group
    end

    ActiveRecord::Base.transaction do
      count_before = Group.count
      assert op_class.run(group: { name: 'fine', color: 'green' })
      assert_equal count_before + 1, Group.count
    end
  end

  # `run_sub` (non-bang) delegates to `run`, so a child operation that saves
  # and then fails validation must not leak partial state into the parent
  # transaction.
  def test_run_sub_rolls_back_partial_writes_in_child_op
    child_op = Class.new(RailsOps::Operation::Model::Create) do
      model Group

      def perform
        super
        fail RailsOps::Exceptions::ValidationFailed, 'post-save check failed'
      end
    end

    parent_op = Class.new(RailsOps::Operation) do
      attr_reader :sub_result

      define_method(:perform) do
        @sub_result = run_sub(child_op, group: { name: 'child', color: 'blue' })
      end
    end

    ActiveRecord::Base.transaction do
      count_before = Group.count
      op = parent_op.new
      op.run!
      refute op.sub_result, 'expected run_sub to return false on child validation error'
      assert_equal count_before, Group.count, 'expected child op save to be rolled back'
    end
  end

  # The same protection applies when the failing exception is
  # `ActiveRecord::RecordInvalid` (raised by `model.save!` on a real
  # model validation failure), which is the more common production case.
  def test_run_rolls_back_partial_writes_on_active_record_record_invalid
    op_class = Class.new(RailsOps::Operation::Model::Create) do
      model Group

      def perform
        super
        # Trigger a real ActiveRecord::RecordInvalid on a separate record.
        invalid = Group.new
        invalid.errors.add(:base, 'invalid')
        fail ActiveRecord::RecordInvalid, invalid
      end
    end

    ActiveRecord::Base.transaction do
      count_before = Group.count
      refute op_class.run(group: { name: 'partial', color: 'red' })
      assert_equal count_before, Group.count, 'expected save to be rolled back'
    end
  end

  def test_no_schema
    op = Class.new(RailsOps::Operation) do
      def perform; end
    end

    assert_nothing_raised do
      op.run!(foo: :bar)
    end
  end

  def test_empty_schema
    op = Class.new(RailsOps::Operation) do
      schema
      def perform; end
    end

    assert_raises Schemacop::Exceptions::ValidationError do
      op.run!(foo: :bar)
    end
  end

  def test_empty_schema2
    op = Class.new(RailsOps::Operation) do
      schema2
      def perform; end
    end

    assert_raises Schemacop::Exceptions::ValidationError do
      op.run!(foo: :bar)
    end
  end

  def test_empty_schema3
    op = Class.new(RailsOps::Operation) do
      schema3
      def perform; end
    end

    assert_raises Schemacop::Exceptions::ValidationError do
      op.run!(foo: :bar)
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

  def test_schema2_with_kwargs
    op = Class.new(RailsOps::Operation) do
      schema2 policy_chain: :on_init do
        req :id, :integer
      end
      def perform; end
    end

    op.run!(id: 1)
    assert_raises Schemacop::Exceptions::ValidationError do
      op.run!(id: 'not_an_integer')
    end
  end

  def test_schema2_with_kwargs_only
    op = Class.new(RailsOps::Operation) do
      schema2 policy_chain: :on_init
      def perform; end
    end

    assert op._op_schema.is_a?(Schemacop::Schema2)
  end

  def test_schema3_with_kwargs
    op = Class.new(RailsOps::Operation) do
      schema3 :hash, title: 'test' do
        int! :id
      end
      def perform; end
    end

    op.run!(id: 1)
    assert_raises Schemacop::Exceptions::ValidationError do
      op.run!(id: 'not_an_integer')
    end
  end

  def test_schema_default_v2_with_kwargs
    original = RailsOps.config.default_schemacop_version
    RailsOps.config.default_schemacop_version = 2
    op = Class.new(RailsOps::Operation) do
      schema policy_chain: :on_init do
        req :id, :integer
      end
      def perform; end
    end

    op.run!(id: 1)
    assert_raises Schemacop::Exceptions::ValidationError do
      op.run!(id: 'not_an_integer')
    end
  ensure
    RailsOps.config.default_schemacop_version = original
  end

  def test_schema_default_v3_with_kwargs
    original = RailsOps.config.default_schemacop_version
    RailsOps.config.default_schemacop_version = 3
    op = Class.new(RailsOps::Operation) do
      schema title: 'test' do
        int! :id
      end
      def perform; end
    end

    op.run!(id: 1)
    assert_raises Schemacop::Exceptions::ValidationError do
      op.run!(id: 'not_an_integer')
    end
  ensure
    RailsOps.config.default_schemacop_version = original
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
