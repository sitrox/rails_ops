module RailsOps::AuthorizationBackend
  class Abstract
    def authorize!(_operation, *_args)
      fail NotImplementedError
    end

    def exception_class
      @exception_class ||= self.class::EXCEPTION_CLASS.constantize
    rescue NameError
      fail "Unable to constantize exception class #{self.class::EXCEPTION_CLASS.inspect} " \
           "for authorization backend #{self.class.name}. Is the library loaded?"
    end
  end
end
