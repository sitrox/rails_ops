# Internal reference: #25564
module ActiveType
  class TypeCaster
    def type_cast_from_user(value)
      # For some reason, Rails defines additional type casting logic
      # outside the classes that have that responsibility.
      case @type
      when :integer
        if value == ''
          nil
        else
          native_type_cast_from_user(value)
        end
      when :timestamp, :datetime
        time = native_type_cast_from_user(value)
        if time && ActiveRecord::Base.time_zone_aware_attributes
          time = ActiveSupport::TimeWithZone.new(nil, Time.zone, time)
        end
        time
      when Integer.class
        if value == ''
          nil
        else
          value.to_i
        end
      else
        native_type_cast_from_user(value)
      end
    end

    module NativeCasters
      class DelegateToType
        def initialize(type, connection)
          # The specified type (e.g. "string") may not necessary match the
          # native type ("varchar") expected by the connection adapter.
          # PostgreSQL is one of these. Perform a translation if the adapter
          # supports it (but don't turn a mysql boolean into a tinyint).
          if !type.nil? && !(type == :boolean) && type.respond_to?(:to_sym) && connection.respond_to?(:native_database_types)
            native_type = connection.native_database_types[type.try(:to_sym)]
            if native_type && native_type[:name]
              type = native_type[:name]
            else
              # unknown type, we just dont cast
              type = nil
            end
          end
          @active_record_type = connection.lookup_cast_type(type)
        end
      end
    end
  end
end
