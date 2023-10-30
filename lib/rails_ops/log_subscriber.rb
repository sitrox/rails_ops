module RailsOps
  # This class subscribes to Rails Ops events via the ActiveSupport
  # instrumentation API.
  class LogSubscriber < ActiveSupport::LogSubscriber
    # This gets called whenever an operation has been performed and logs the
    # operation via Rails' `debug` logging method.
    def run(event)
      op = event.payload[:operation]

      return if op.class.logging_skipped?

      profile = ::RailsOps::Profiler.node(op.object_id)

      message = 'OP'
      message += ' FAILED' if profile.erroneous?
      message += " (#{profile.t_self_ms.round(1)}ms / #{profile.t_kids_ms.round(1)}ms)"
      profile.free

      color = profile.erroneous? ? RED : YELLOW

      message = color(message, color, true)
      message += color(" #{op.class.name}", color, false)

      debug "  #{message}"
    end

    private

    def color(message, color, bold = false)
      # Passing the value for bold is deprecated in Rails 7.1 and will
      # be removed in Rails 7.2. As RailsOps is currently also supporting
      # Rails 6.x, we need to use the correct method.
      if Rails.gem_version >= Gem::Version.new('7.1')
        super(message, color, bold: bold)
      else
        super(message, color, bold)
      end
    end
  end
end
