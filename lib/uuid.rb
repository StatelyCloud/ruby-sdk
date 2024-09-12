# frozen_string_literal: true

module StatelyDB
  # UUID is a helper class for working with UUIDs in StatelyDB. The ruby version of a StatelyDB is a binary string,
  # and this class provides convenience methods for converting to the base16 representation specified in RFC 9562.
  # Internally this class uses the byte_string attribute to store the UUID as a string with the Encoding::ASCII_8BIT
  # encoding.
  class UUID
    attr_accessor :byte_string

    # @param [String] byte_string A binary-encoded string (eg: Encoding::ASCII_8BIT encoding)
    def initialize(byte_string)
      @byte_string = byte_string
    end

    # to_s returns the UUID as a base16 string (eg: "f4a8a24a-129d-411f-91d2-6d19d0eaa096")
    # @return [String]
    def to_s
      to_str
    end

    # to_str returns the UUID as a base16 string (eg: "f4a8a24a-129d-411f-91d2-6d19d0eaa096")
    #
    # Note: to_str is a type coercion method that is called by Ruby when an object is coerced to a string.
    # @return [String]
    def to_str
      @byte_string.unpack("H8H4H4H4H12").join("-")
    end

    # Encodes the byte string as a url-safe base64 string with padding removed.
    # @return [String]
    def to_base64
      [@byte_string].pack("m0").tr("=", "").tr("+/", "-_")
    end

    # UUIDs are equal if their byte_strings are equal.
    # @param [StatelyDB::UUID] other
    # @return [Boolean]
    def ==(other)
      self.class == other.class &&
        @byte_string == other.byte_string
    end

    # UUIDs are sorted lexigraphically by their base16 representation.
    # @param [StatelyDB::UUID] other
    # @return [Integer]
    def <=>(other)
      to_s <=> other.to_s
    end

    # Returns true if the UUID is empty.
    # @return [Boolean]
    def empty?
      @byte_string.empty?
    end

    # Parses a base16 string (eg: "f4a8a24a-129d-411f-91d2-6d19d0eaa096") into a UUID object.
    # The string can be the following:
    # 1. Encoded as Encoding::ASCII_8BIT (also aliased as Encoding::BINARY) and be 16 bytes long.
    # 2. A string of the form "f4a8a24a-129d-411f-91d2-6d19d0eaa096"
    # @param [String] byte_string A binary-encoded string (eg: Encoding::ASCII_8BIT encoding) that is 16 bytes in length, or a
    #                             base16-formatted UUID string.
    # @return [StatelyDB::UUID]
    def self.parse(byte_string)
      return byte_string if byte_string.is_a?(StatelyDB::UUID)

      if valid_uuid?(byte_string)
        return new(byte_string)
      elsif byte_string.match(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i)
        return new([byte_string.delete("-")].pack("H*"))
      end

      raise "Invalid UUID"
    end

    # Not all bytes values in StatelyDB are UUIDs. This method checks if a byte string is a valid UUID.
    # @param [String] byte_string A binary-encoded string (eg: Encoding::ASCII_8BIT encoding)
    # @return [Boolean]
    def self.valid_uuid?(byte_string)
      byte_string.encoding == Encoding::BINARY && byte_string.bytesize == 16
    end
  end
end
