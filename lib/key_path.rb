# frozen_string_literal: true

module StatelyDB
  # KeyPath is a helper class for constructing key paths.
  class KeyPath
    def initialize
      super
      @path = []
    end

    # Appends a new path segment.
    # @param [String] namespace
    # @param [String, StatelyDB::UUID, #to_s] identifier
    # @return [KeyPath]
    def with(namespace, identifier = nil)
      if identifier.nil?
        @path << namespace
        return self
      end
      @path << "#{namespace}-#{self.class.to_key_id(identifier)}"
      self
    end

    # @return [String]
    def to_str
      "/".dup.concat(@path.join("/"))
    end

    # @return [String]
    def inspect
      to_str
    end

    # @return [String]
    def to_s
      to_str
    end

    # Appends a new path segment.
    # @param [String] namespace
    # @param [String, StatelyDB::UUID, #to_s] identifier
    # @return [KeyPath]
    #
    # @example
    #  keypath = KeyPath.with("genres", "rock").with("artists", "the-beatles")
    def self.with(namespace, identifier = nil)
      new.with(namespace, identifier)
    end

    # If the value is a binary string, encode it as a url-safe base64 string with padding removed.
    #
    # @param [String, StatelyDB::UUID, #to_s] value The value to convert to a key id.
    # @return [String]
    def self.to_key_id(value)
      if value.is_a?(StatelyDB::UUID)
        value.to_base64
      elsif value.is_a?(String) && value.encoding == Encoding::BINARY
        [value].pack("m0").tr("=", "").tr("+/", "-_")
      else
        # Any other value is just converted to a string
        value.to_s
      end
    end
  end
end
