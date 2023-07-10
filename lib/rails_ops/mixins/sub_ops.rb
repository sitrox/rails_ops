# Mixin for the {RailsOps::Operation} class that provides a simple way of
# running arbitrary operations within operations, automatically passing a
# modified version of the current operation's context to them.
module RailsOps::Mixins::SubOps
  extend ActiveSupport::Concern

  # Instantiates and returns a new operation of the given class and
  # automatically passes a modified version of the current operation's context
  # to it. For one-line runs of operations please use {run_sub!} or {run_sub}
  # which internally use this method.
  def sub_op(op, params = {})
    new_context = context.spawn(self)
    return op.new(new_context, params)
  rescue *op.validation_errors => e
    fail RailsOps::Exceptions::SubOpValidationFailed, e
  end

  # Operation-equivalent of controller method 'run!': Instantiates and runs the
  # given operation class. See {sub_op} for more details on how instantiation
  # and context modification is done.
  def run_sub!(klass, params = {})
    op = sub_op(klass, params)

    begin
      return op.run!
    rescue *op.validation_errors => e
      fail RailsOps::Exceptions::SubOpValidationFailed, e
    end
  end

  # Operation-equivalent of controller method 'run': Instantiates and runs the
  # given operation class. See {sub_op} for more details on how instantiation
  # and context modification is done.
  def run_sub(op, params = {})
    sub_op(op, params).run
  end
end
