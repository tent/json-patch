class JsonPatch

  class HashPointer
    InvalidPointerError = Class.new(StandardError)

    def initialize(hash, pointer)
      @hash, @pointer = hash, pointer
    end

    def value
      keys.inject(@hash) do |obj, key|
        if obj.kind_of?(Array)
          raise InvalidPointerError if key.to_i >= obj.size
          obj[key.to_i]
        elsif obj.kind_of?(Hash)
          raise InvalidPointerError unless obj.has_key?(key)
          obj[key]
        else
          raise InvalidPointerError
        end
      end
    end

    def value=(value)
      if exists? && value_class == Array && keys.last !~ /^\d+$/
        raise InvalidPointerError
      end
      obj = keys[0..-2].inject(@hash) do |obj, key|
        obj[key] = {} unless [Hash, Array].include?(obj[key].class)
        obj[key]
      end
      if obj.kind_of?(Array)
        obj.insert(keys.last.to_i, value)
      else
        obj[keys.last] = value
      end
    end

    def delete
      obj = keys[0..-2].inject(@hash) do |obj, key|
        obj[key]
      end
      if obj.kind_of?(Array)
        raise InvalidPointerError if keys.last.to_i >= obj.size
        obj.delete_at(keys.last.to_i)
      else
        raise InvalidPointerError unless obj.has_key?(keys.last)
        obj.delete(keys.last)
      end
    end

    def move_to(pointer)
      _value = value
      to_pointer = self.class.new(@hash, pointer)
      if value_class == Array && to_pointer.value_class == Array && to_pointer.keys.last !~ /^\d+$/
        raise InvalidPointerError
      end
      delete
      to_pointer.value = _value
    end

    def exists?
      i = 0
      keys.inject(@hash) do |obj, key|
        # points to a key that doesn't exist
        break unless obj

        if obj.kind_of?(Array)
          return key.to_i < obj.size
        end

        return true if obj.kind_of?(Hash) && i == keys.size-1 && obj.has_key?(key)

        return false if obj[key].nil?

        return true if ![Hash, Array].include?(obj[key].class)

        i += 1
        obj[key]
      end
      false
    end

    def value_class
      i = 0
      keys.inject(@hash) do |obj, key|
        return unless obj

        return Array if obj.kind_of?(Array)
        return Hash if i == keys.size-1 && obj[key].kind_of?(Hash)

        i += 1
        obj[key]
      end
    end

    def keys
      @pointer.sub(%r{^/}, '').split("/").map do |key|
        unescape_key(key)
      end
    end

    def unescape_key(key)
      key.gsub(/~1/, '/').gsub(/~0/, '~')
    end
  end

end
