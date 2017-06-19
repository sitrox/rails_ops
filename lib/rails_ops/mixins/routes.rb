module RailsOps::Mixins::Routes
  extend ActiveSupport::Concern

  class RoutingContainer
    def initialize(url_options)
      @url_options = url_options
    end

    def method_missing(name, *args)
      Rails.application.routes.url_helpers.send(name, *args, @url_options)
    end
  end

  def routes
    unless @routes
      if context.url_options.nil?
        fail RailsOps::Exceptions::RoutingNotAvailable,
             'Can not access routes helpers, no url_options given in context.'
      end

      @routes = RoutingContainer.new(context.url_options)
    end

    return @routes
  end
end
