module RailsOps
  # @private
  class Railtie < Rails::Railtie
    # Register the deprecator early so that app-level deprecation config
    # (`config.active_support.deprecation`,
    # `config.active_support.report_deprecations`, …) is applied to it.
    initializer 'rails_ops.deprecator', before: :load_environment_config do |app|
      if app.respond_to?(:deprecators)
        app.deprecators[:rails_ops] = RailsOps.deprecator
      end
    end

    initializer 'rails_ops' do
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
