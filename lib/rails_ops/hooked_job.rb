module RailsOps
  # This class extends ActiveJob::Job and, when subclassed, allows to link
  # common job classes to operations. When defining a Job, just extend this
  # class and use the static `op` method in order to hook it to a specific
  # operation. The `perform` method will then automatically run the operation
  # via its `run!` method and with the given params.
  class HookedJob < ActiveJob::Base
    class_attribute :operation_class

    # Set an operation class this job shall be hooked with. This is mandatory
    # unless you override the `perform` method (which would be an abuse of this
    # class anyways).
    def self.op(klass)
      self.operation_class = klass
    end

    # This method is called by the ActiveJob framework and solely executes the
    # hooked operation's `run!` method. If no operation has been hooked (use the
    # static method `op` for that), it will raise an exception.
    def perform(params = {})
      fail 'This job is not hooked to any operation.' unless operation_class
      operation_class.run!(params)
    end
  end
end
