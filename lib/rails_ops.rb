module RailsOps
  AUTH_THREAD_STORAGE_KEY = :rails_ops_authorization_enabled

  def self.config
    @config ||= Configuration.new
  end

  def self.configure(&_block)
    yield(config)
  end

  def self.authorization_backend
    return nil unless config.authorization_backend
    return @authorization_backend ||= config.authorization_backend.constantize.new
  end

  # Returns an instance of the {RailsOps::Hookup} class. This instance is
  # cached depending on the application environment.
  def self.hookup
    Hookup.instance
  end

  def self.authorization_enabled?
    fail 'No authorization backend is configured.' unless authorization_backend

    return false unless authorization_backend

    if Thread.current[AUTH_THREAD_STORAGE_KEY].nil?
      return true
    else
      return Thread.current[AUTH_THREAD_STORAGE_KEY]
    end
  end

  # Operations within the given block will have disabled authorization.
  # This only applies to the current thread.
  def self.without_authorization(&_block)
    previous_value = Thread.current[AUTH_THREAD_STORAGE_KEY]
    Thread.current[AUTH_THREAD_STORAGE_KEY] = false
    yield
    Thread.current[AUTH_THREAD_STORAGE_KEY] = previous_value
  end
end
