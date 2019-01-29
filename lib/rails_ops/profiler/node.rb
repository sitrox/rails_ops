module RailsOps
  class Profiler::Node
    def initialize(object_id, description = nil, parent = nil)
      @object_id = object_id
      @description = description
      @parent = parent
      parent.add_child(self) if parent
      @children = []
      @erroneous = false
      @t_start = Time.now
    end

    attr_reader :parent
    attr_reader :description

    def finish_measure
      @t_stop = Time.now
    end

    def erroneous!
      @erroneous = true
    end

    def erroneous?
      @erroneous
    end

    def t_self
      t_total - t_kids
    end

    def t_kids
      @children.map(&:t_total).inject(:+) || 0
    end

    def t_total
      return nil unless @t_stop
      (@t_stop - @t_start).to_f
    end

    def t_self_s
      t_self
    end

    def t_kids_s
      t_kids
    end

    def t_total_s
      t_total
    end

    def t_self_ms
      t_self * 1000
    end

    def t_kids_ms
      t_kids * 1000
    end

    def t_total_ms
      t_total * 1000
    end

    def free
      ::RailsOps::Profiler.forget(@object_id) unless parent
    end

    def add_child(child)
      @children << child
    end
  end
end
