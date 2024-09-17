# frozen_string_literal: true

require "base64"
require "securerandom"
require "spec_helper"
require "statelydb"

test_uuid = "f4a8a24a-129d-411f-91d2-6d19d0eaa096"

# This test is meant to validate conversions using StatelyDB::KeyPath
describe StatelyDB::KeyPath do
  it "supports single-level paths" do
    path = described_class.with("foo", "bar")
    expect(path.to_s).to eq("/foo-bar")

    path = described_class.with("foo", "1234")
    expect(path.to_s).to eq("/foo-1234")

    stately_uuid = StatelyDB::UUID.parse(test_uuid)
    path = described_class.with("foo", stately_uuid)
    expect(path.to_s).to eq("/foo-9KiiShKdQR-R0m0Z0Oqglg")
  end

  it "supports multi-level paths" do
    path = described_class.with("foo", "bar").with("baz", "qux").with("quux", "corge")
    expect(path.to_s).to eq("/foo-bar/baz-qux/quux-corge")
  end

  it "supports partial paths" do
    path = described_class.with("foo", "bar").with("namespace")
    expect(path.to_s).to eq("/foo-bar/namespace")
  end

  it "supports empty paths" do
    path = described_class.new
    expect(path.to_s).to eq("/")
  end

  it "can make a key_id from a UUID" do
    stately_uuid = StatelyDB::UUID.parse("00000000-0000-0000-0000-000000000005")
    expect(described_class.to_key_id(stately_uuid)).to eq("AAAAAAAAAAAAAAAAAAAABQ")
  end

  it "can make a key_id from a String" do
    expect(described_class.to_key_id("batman")).to eq("batman")
  end

  it "can make a key_id from a binary-encoded String" do
    binary_string = String.new([0x00, 0x01, 0x02, 0x03].pack("C*"), encoding: "ASCII-8BIT")
    expect(described_class.to_key_id(binary_string)).to eq("AAECAw")
  end

  it "can make a key_id from an Integer" do
    expect(described_class.to_key_id(1234)).to eq("1234")
  end
end
