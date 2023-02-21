module RailsOps::Mixins::Routes
  extend ActiveSupport::Concern

  # This class can't be defined at load time of this file as `Rails.application`
  # would not exist at this point in time. Instead, we're creating and caching
  # this class on the first call. This is not thread-safe, but the worst case is
  # that this is performed more than once.
  def self.container_class
    @container_class ||= Class.new do
      include Rails.application.routes.url_helpers

      attr_reader :url_options

      def initialize(url_options)
        @url_options = url_options
      end
    end
  end

  # Returns an object that responds to all URL helper methods using the
  # `url_options` provided with the operation's context. If no URL options are
  # given, this method will raise an exception.
  def routes
    unless @routes
      if context.url_options.nil?
        fail RailsOps::Exceptions::RoutingNotAvailable,
             'Can not access routes helpers, no url_options given in context.'
      end

      @routes = RailsOps::Mixins::Routes.container_class.new(context.url_options)
    end

    return @routes
  end
end
