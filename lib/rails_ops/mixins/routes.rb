module RailsOps::Mixins::Routes
  extend ActiveSupport::Concern

  included do
  end

  class RoutingContainer
    include Rails.application.routes.url_helpers

    attr_reader :url_options

    def initialize(url_options)
      @url_options = url_options
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
