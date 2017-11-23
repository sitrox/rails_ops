require 'test_helper'

class RailsOps::Operation::ExampleTest < Minitest::Test
  include TestHelper

  def setup
    self.class.setup_db
    self.class.setup_base_data
  end

  def test_group_create
    Group.create name: 'Test', color: 'blue'
  end
end
