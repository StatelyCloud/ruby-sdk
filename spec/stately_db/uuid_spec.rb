# frozen_string_literal: true

require "spec_helper"
require "statelydb"

# This test is meant to validate conversions using StatelyDB::UUID
describe StatelyDB::UUID do
  it "handles UUID parsing and conversion" do
    # The ruby stdlib has a way to generate UUIDs (v4, v7) but only as base16-formatted strings, not the raw bytes. We
    # want to play with both, so we're recreating the steps the stdlib does internally here (see Random::Formatter).

    # First a byte string with 16 random bytes (eg: 16 bytes; 128 bits).
    uuid_byte_string = SecureRandom.random_bytes(16)
    expect(uuid_byte_string).to be_a(String)
    expect(uuid_byte_string.bytesize).to eq(16)
    expect(uuid_byte_string.encoding).to eq(Encoding::ASCII_8BIT)

    # Next, convert the byte string to a UUID string (eg: base16 with dashes). Note that we're modifying raw bytes with
    # two bitwise operations to set the UUID variant per https://www.rfc-editor.org/rfc/rfc9562#name-uuid-version-4.
    uuid_byte_string.setbyte(6, (uuid_byte_string.getbyte(6) & 0x0f) | 0x40)
    uuid_byte_string.setbyte(8, (uuid_byte_string.getbyte(8) & 0x3f) | 0x80)
    uuid_base16_string = uuid_byte_string.unpack("H8H4H4H4H12").join("-")
    expect(uuid_base16_string).to be_a(String)

    # Test that we can parse a base16 value and when we convert back to a base16 it matches the original
    uuid1 = described_class.parse(uuid_base16_string)
    expect(uuid1).to be_a(described_class)
    expect(uuid1.byte_string).to eq(uuid_byte_string)
    expect(uuid1.to_s).to eq(uuid_base16_string)

    # Test that we can parse a byte string and when we convert back to a base16 it matches the original
    uuid2 = described_class.parse(uuid_byte_string)
    expect(uuid2).to be_a(described_class)
    expect(uuid2.byte_string).to eq(uuid_byte_string)
    expect(uuid2.to_s).to eq(uuid_base16_string)
  end
end
