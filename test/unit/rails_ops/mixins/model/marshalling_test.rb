require 'test_helper'

class RailsOps::Mixins::Model::MarshallingTest < ActiveSupport::TestCase
  include TestHelper

  class RailsOps::Mixins::Model::MarshallingTest::ParentOp < RailsOps::Operation::Model::Create
    model Group
    attr_reader :loaded_child_class
    attr_reader :loaded_child_parent_op

    def perform
      sub_op = run_sub! RailsOps::Mixins::Model::MarshallingTest::ChildOp

      dump_res = Marshal.dump(sub_op)
      # rubocop:disable Security/MarshalLoad
      load_res = Marshal.load(dump_res)
      # rubocop:enable Security/MarshalLoad

      @loaded_child_class = load_res.class
      @loaded_child_parent_op = load_res.model.parent_op
    end
  end

  class RailsOps::Mixins::Model::MarshallingTest::ChildOp < RailsOps::Operation::Model::Create
    model Group
    def perform; end
  end

  def test_marshal_dump_and_load
    assert_nothing_raised do
      op_res = RailsOps::Mixins::Model::MarshallingTest::ParentOp.run!
      assert_equal RailsOps::Mixins::Model::MarshallingTest::ChildOp, op_res.loaded_child_class
      assert_nil op_res.loaded_child_parent_op
    end
  end
end
