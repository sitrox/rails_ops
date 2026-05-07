require 'test_helper'

class RailsOps::RailtieTest < ActiveSupport::TestCase
  include TestHelper

  def test_deprecator_is_registered_with_rails
    skip 'Rails.application.deprecators is unavailable on this Rails version' \
      unless Rails.application.respond_to?(:deprecators)

    registered = Rails.application.deprecators[:rails_ops]
    assert_same RailsOps.deprecator, registered,
                'expected RailsOps.deprecator to be registered as Rails.application.deprecators[:rails_ops]'
  end

  def test_deprecator_honors_silenced_flag_set_via_app_config
    skip 'Rails.application.deprecators is unavailable on this Rails version' \
      unless Rails.application.respond_to?(:deprecators)

    previous_silenced = RailsOps.deprecator.silenced
    begin
      Rails.application.deprecators.silenced = true
      assert RailsOps.deprecator.silenced,
             'expected RailsOps.deprecator to be silenced when ' \
             'Rails.application.deprecators.silenced = true'
    ensure
      Rails.application.deprecators.silenced = previous_silenced
    end
  end
end
