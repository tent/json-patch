require "json-patch/version"
require "json-patch/hash_pointer"

class JsonPatch
  OPERATIONS = %w( add remove replace move copy test )

  ObjectExistsError = Class.new(StandardError)
  ObjectNotFoundError = Class.new(StandardError)

  class << self
    def merge(object, patch)
      patch.each do |patch_object|
        operation = OPERATIONS.find { |key| !patch_object[key].nil? }
        send(operation, object, patch_object)
      end
      object
    end

    def add(object, patch_object)
      pointer = HashPointer.new(object, patch_object["add"])
      if pointer.exists?
        raise ObjectExistsError unless pointer.value_class == Array
      end
      pointer.value = patch_object["value"]
      object
    rescue HashPointer::InvalidPointerError => e
      raise ObjectExistsError
    end

    def remove(object, patch_object)
      pointer = HashPointer.new(object, patch_object["remove"])
      pointer.delete
      object
    rescue HashPointer::InvalidPointerError => e
      raise ObjectNotFoundError
    end

    def replace(object, patch_object)
      pointer = HashPointer.new(object, patch_object["replace"])
      pointer.delete
      pointer.value = patch_object["value"]
      object
    rescue HashPointer::InvalidPointerError => e
      raise ObjectNotFoundError
    end

    def move(object, patch_object)
      pointer = HashPointer.new(object, patch_object["move"])
      pointer.move_to patch_object["to"]
    rescue HashPointer::InvalidPointerError => e
      raise ObjectNotFoundError
    end

    def copy(object, patch_object)
      from_pointer = HashPointer.new(object, patch_object["copy"])
      add(object, { "add" => patch_object["to"], "value" => from_pointer.value })
    rescue HashPointer::InvalidPointerError => e
      raise ObjectNotFoundError
    end

    def test(object, patch_object)
      pointer = HashPointer.new(object, patch_object["test"])
      raise ObjectNotFoundError unless pointer.exists?
      raise ObjectNotFoundError unless pointer.value == patch_object["value"]
    end
  end
end
