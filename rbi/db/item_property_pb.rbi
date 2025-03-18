# Code generated by protoc-gen-rbi. DO NOT EDIT.
# source: db/item_property.proto
# typed: strict

module Stately::Db::SortableProperty
  self::SORTABLE_PROPERTY_KEY_PATH = T.let(0, Integer)
  self::SORTABLE_PROPERTY_LAST_MODIFIED_VERSION = T.let(1, Integer)
  self::SORTABLE_PROPERTY_GROUP_LOCAL_INDEX_1 = T.let(8, Integer)
  self::SORTABLE_PROPERTY_GROUP_LOCAL_INDEX_2 = T.let(9, Integer)
  self::SORTABLE_PROPERTY_GROUP_LOCAL_INDEX_3 = T.let(10, Integer)
  self::SORTABLE_PROPERTY_GROUP_LOCAL_INDEX_4 = T.let(11, Integer)

  sig { params(value: Integer).returns(T.nilable(Symbol)) }
  def self.lookup(value)
  end

  sig { params(value: Symbol).returns(T.nilable(Integer)) }
  def self.resolve(value)
  end

  sig { returns(::Google::Protobuf::EnumDescriptor) }
  def self.descriptor
  end
end
