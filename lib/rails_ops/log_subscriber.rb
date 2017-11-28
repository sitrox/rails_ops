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
  end
end
