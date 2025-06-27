# frozen_string_literal: true

require "api/db/service_services_pb"

def build_filters(item_types: [], cel_filters: [])
  filters = item_types.map do |item_type|
    Stately::Db::FilterCondition.new(item_type: item_type.respond_to?(:name) ? item_type.name.split("::").last : item_type)
  end
  filters += cel_filters.map do |filter|
    Stately::Db::FilterCondition.new(
      cel_expression: {
        item_type: filter[0].respond_to?(:name) ? filter[0].name.split("::").last : filter[0],
        expression: filter[1]
      }
    )
  end
  filters
end
