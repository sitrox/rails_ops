module RailsOps
  class Profiler
    def self.profile(object_id, description = nil, &_block)
      node = tstore_nodes[object_id] = ::RailsOps::Profiler::Node.new(object_id, description, tstore_current_parent)
      self.tstore_current_parent = node
      res = yield
      self.tstore_current_parent = node.parent
      node.finish_measure
      res
    end

    def self.time(descr = nil, &_block)
      descr += ' - ' if descr
      start = Time.now
      res = yield
      puts "#{descr}#{((Time.now - start).to_f * 1000).round(1)}ms elapsed.".magenta
      res
    end

    def self.forget_all
      Thread.current[:rails_ops_profiler][:nodes] = {}
    end

    def self.forget(object_id)
      tstore_nodes.delete(object_id)
    end

    def self.node(object_id)
      tstore_nodes[object_id] || fail("Unkown object_id #{object_id}.")
    end

    def self.tstore_current_parent
      Thread.current[:rails_ops_profiler] ||= {}
      Thread.current[:rails_ops_profiler][:current_parent]
    end

    def self.tstore_current_parent=(parent)
      Thread.current[:rails_ops_profiler] ||= {}
      Thread.current[:rails_ops_profiler][:current_parent] = parent
    end

    def self.tstore_nodes
      Thread.current[:rails_ops_profiler] ||= {}
      Thread.current[:rails_ops_profiler][:nodes] ||= {}
    end
  end
end
