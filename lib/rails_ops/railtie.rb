module RailsOps
  # @private
  class Railtie < Rails::Railtie
    initializer 'rails_ops' do |app|
      # ---------------------------------------------------------------
      # Register deprecator
      # ---------------------------------------------------------------
      if app.respond_to?(:deprecators)
        app.deprecators[:rails_ops] = RailsOps.deprecator
      end

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
      ActiveSupport.on_load :action_controller_base do
        include RailsOps::ControllerMixin
      end
    end
  end
end
