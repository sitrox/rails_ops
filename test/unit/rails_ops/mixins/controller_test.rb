require 'test_helper'
require 'cancancan'

class RailsOps::Mixins::ControllerTest < ActionDispatch::IntegrationTest
  include TestHelper

  def test_controller_op
    group = Group.create(name: 'group')
    get group_url(group), as: :json
    assert_equal 'group', JSON.parse(@response.body)['name']
  end

  def test_controller_op_run
    group = Group.create(name: 'group')
    patch group_url(group), params: { name: 'group2' }, as: :json
    assert_equal 'group2', JSON.parse(@response.body)['name']

    group.reload
    assert_equal 'group2', group.name
  end
end
