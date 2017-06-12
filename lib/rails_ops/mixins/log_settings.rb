module RailsOps::Mixins::LogSettings
  extend ActiveSupport::Concern

  included do
    class_attribute :_skip_logging
    self._skip_logging = false
  end

  module ClassMethods
    # Allows to skip logging for this operation via the
    # {RailsOps::LogSubscriber}.
    def skip_logging(skip = true)
      self._skip_logging = skip
    end

    def logging_skipped?
      _skip_logging
    end
  end
end
