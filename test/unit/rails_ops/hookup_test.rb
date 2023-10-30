require 'test_helper'

class RailsOps::HookupTest < ActiveSupport::TestCase
  include TestHelper

  class RailsOps::HookupTest::HookupStarter < RailsOps::Operation::Model::Create
    model ::Group
  end

  class RailsOps::HookupTest::HookupTarget < RailsOps::Operation
    def perform
      Group.find_by(name: 'hookup_test_group').update({ color: 'blue' })
    end
  end

  def test_hooked_op
    group = RailsOps::HookupTest::HookupStarter.run!(group: { name: 'hookup_test_group' }).model
    group.reload
    assert_equal 'blue', group.color
  end

  def test_recursive_hookup_raises
    RailsOps.hookup.instance_variable_set(:@drawn, false)
    RailsOps.hookup.instance_variable_set(:@config_loaded, false)
    assert_raises SystemStackError do
      RailsOps.hookup.draw do
        run 'RailsOps::HookupTest::HookupTarget' do
          on 'RailsOps::HookupTest::HookupStarter'
        end

        run 'RailsOps::HookupTest::HookupStarter' do
          on 'RailsOps::HookupTest::HookupTarget'
        end
      end
    end
    RailsOps.hookup.load_config
  end

  def test_dont_draw_twice
    RailsOps.hookup.load_config
    assert_raises_with_message RuntimeError, "Hooks can't be drawn twice." do
      RailsOps.hookup.draw do
        run 'RailsOps::HookupTest::HookupTarget' do
          on 'RailsOps::HookupTest::HookupStarter'
        end
      end
    end
  end

  def test_missing_hookup_op
    RailsOps.hookup.load_config
    RailsOps.hookup.instance_variable_set(:@drawn, false)
    RailsOps.hookup.draw do
      run 'RailsOps::HookupTest::HookupIllusiveTarget' do
        on 'RailsOps::HookupTest::HookupStarter'
      end
    end

    assert_raises_with_message RuntimeError, 'Could not find hook target operation RailsOps::HookupTest::HookupIllusiveTarget.' do
      RailsOps::HookupTest::HookupStarter.run!(group: { name: 'group' })
    end

    RailsOps.hookup.instance_variable_set(:@drawn, false)
    RailsOps.hookup.instance_variable_set(:@config_loaded, false)
    RailsOps.hookup.load_config
  end

  def test_missing_config_file
    orig_path = RailsOps::Hookup::CONFIG_PATH
    RailsOps::Hookup.send(:remove_const, :CONFIG_PATH)
    RailsOps::Hookup.const_set(:CONFIG_PATH, '/def/doesnt/exist')
    RailsOps.hookup.instance_variable_set(:@drawn, false)
    RailsOps.hookup.instance_variable_set(:@config_loaded, false)
    assert_nothing_raised do
      RailsOps.hookup.load_config
    end
    assert_equal({}, RailsOps.hookup.hooks)

    RailsOps::Hookup.send(:remove_const, :CONFIG_PATH)
    RailsOps::Hookup.const_set(:CONFIG_PATH, orig_path)
    RailsOps.hookup.instance_variable_set(:@drawn, false)
    RailsOps.hookup.instance_variable_set(:@config_loaded, false)
    RailsOps.hookup.load_config
  end
end
