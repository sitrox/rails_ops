require File.expand_path('../../test/dummy/config/environment.rb', __FILE__)
# ActiveRecord::Migrator.migrations_paths = [File.expand_path("../../test/dummy/db/migrate", __FILE__)]
require 'rails/test_help'
require 'pry'
require 'colorize'

# Filter out Minitest backtrace while allowing backtrace from other libraries
# to be shown.
Minitest.backtrace_filter = Minitest::BacktraceFilter.new

require 'rails/test_unit/reporter'

Rails::TestUnitReporter.executable = 'bin/test'

# Load fixtures from the engine
if ActiveSupport::TestCase.respond_to?(:fixture_path=)
  ActiveSupport::TestCase.fixture_path = File.expand_path('../fixtures', __FILE__)
  ActionDispatch::IntegrationTest.fixture_path = ActiveSupport::TestCase.fixture_path
  ActiveSupport::TestCase.file_fixture_path = ActiveSupport::TestCase.fixture_path + '/files'
  ActiveSupport::TestCase.fixtures :all
end

load File.dirname(__FILE__) + '/dummy/db/schema.rb'

require 'request_store'

module TestHelper
  extend ActiveSupport::Concern

  # Help test raise errors message
  # https://ruby-doc.org/stdlib-2.1.5/libdoc/test/unit/rdoc/Test/Unit/Assertions.html#method-i-assert_raise
  def assert_raises_with_message(exception, expected, msg = nil, &block)
    case expected
    when String
      assert = :assert_equal
    when Regexp
      assert = :assert_match
    else
      fail TypeError, "Expected #{expected.inspect} to be a kind of String or Regexp, not #{expected.class}"
    end

    ex = assert_raises(exception, *msg) { yield }
    msg = message(msg, '') { "Expected Exception(#{exception}) was raised, but the message doesn't match" }

    if assert == :assert_equal
      assert_equal(expected, ex.message, msg)
    else
      msg = message(msg) { "Expected #{mu_pp expected} to match #{mu_pp ex.message}" }
      assert expected =~ ex.message, msg
      block.binding.eval('proc{|_|$~=_}').call($LAST_MATCH_INFO)
    end

    return ex
  end
end
