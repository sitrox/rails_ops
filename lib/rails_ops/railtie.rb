module RailsOps
  # @private
  class Railtie < Rails::Railtie
    initializer 'rails_ops' do |_app|
      # ---------------------------------------------------------------
      # Load hookup config eagerly at application startup unless
      # in development mode.
      # ---------------------------------------------------------------
      unless Rails.env.development?
        RailsOps.hookup.load_config
      end

      # ---------------------------------------------------------------
      # Attach log subscriber to rails.
      # ---------------------------------------------------------------
      RailsOps::LogSubscriber.attach_to :rails_ops

      # ---------------------------------------------------------------
      # Include controller mixin
      # ---------------------------------------------------------------
      ActionController::Base.send :include, RailsOps::ControllerMixin
    end
  end
end
