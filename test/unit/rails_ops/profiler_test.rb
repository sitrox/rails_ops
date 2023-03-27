class RailsOps::ProfilerTest < ActiveSupport::TestCase
  include TestHelper

  def test_time
    assert_output(/Test - 1\d\.\dms elapsed./) do
      RailsOps::Profiler.time 'Test' do
        sleep 0.010
      end
    end
  end
end
