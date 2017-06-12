module RailsOps
  # This class subscribes to Rails Ops events via the ActiveSupport
  # instrumentation API.
  class LogSubscriber < ActiveSupport::LogSubscriber
    # This gets called whenever an operation has been performed and logs the
    # operation via Rails' `debug` logging method.
    def run(event)
      op = event.payload[:operation]

      return if op.class.logging_skipped?

      message = 'OP'

      profile = ::RailsOps::Profiler.node(op.object_id)
      message += " (#{profile.t_self_ms.round(1)}ms / #{profile.t_kids_ms.round(1)}ms)"
      profile.free

      message = color(message, YELLOW, true)
      message += color(" #{op.class.name}", YELLOW, false)

      debug "  #{message}"
    end
  end
end
