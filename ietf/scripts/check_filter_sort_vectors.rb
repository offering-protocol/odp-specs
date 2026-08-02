#!/usr/bin/env ruby
# frozen_string_literal: true

require "date"
require "json"
require "pathname"
require "time"

IDENTIFIER = /\A[A-Za-z0-9._~-]{1,64}\z/
DECIMAL = /\A-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?\z/
TYPES = %w[string boolean integer number decimal date date-time].freeze
OPERATORS = %w[eq in lt lte gt gte exists].freeze
ORDERED_TYPES = %w[integer number decimal date date-time].freeze

def scalar_valid?(type, value)
  case type
  when "string" then value.is_a?(String)
  when "boolean" then [true, false].include?(value)
  when "integer" then value.is_a?(Integer)
  when "number" then value.is_a?(Numeric)
  when "decimal" then value.is_a?(String) && value.match?(DECIMAL)
  when "date"
    value.is_a?(String) && Date.iso8601(value).to_s == value
  when "date-time"
    value.is_a?(String) && !Time.iso8601(value).nil?
  else false
  end
rescue Date::Error, ArgumentError
  false
end

def unit_valid?(unit)
  return false unless unit.is_a?(Hash) && unit["code"].is_a?(String) && !unit["code"].empty?

  case unit["system"]
  when "ucum"
    unit["code"].length <= 64
  when "service"
    unit["code"].match?(IDENTIFIER) && unit["title"].is_a?(String) && unit["title"].length.between?(1, 128)
  else false
  end
end

def definition_valid?(definition)
  required = %w[id title description type operators]
  return false unless definition.is_a?(Hash) && required.all? { |field| definition.key?(field) }
  return false unless definition["id"].is_a?(String) && definition["id"].match?(IDENTIFIER)
  return false unless definition["title"].is_a?(String) && definition["title"].length.between?(1, 128)
  return false unless definition["description"].is_a?(String) && definition["description"].length.between?(1, 1024)
  return false unless TYPES.include?(definition["type"])

  operators = definition["operators"]
  return false unless operators.is_a?(Array) && !operators.empty? && operators.uniq.length == operators.length
  return false unless operators.all? { |operator| OPERATORS.include?(operator) }
  return false if (operators & %w[lt lte gt gte]).any? && !ORDERED_TYPES.include?(definition["type"])
  return false if definition.key?("unit") && !%w[integer number decimal].include?(definition["type"])

  !definition.key?("unit") || unit_valid?(definition["unit"])
end

def expression_valid?(definition, expression)
  return false unless definition_valid?(definition) && expression.is_a?(Hash)
  return false unless expression["id"] == definition["id"]

  operator = expression["operator"]
  return false unless definition["operators"].include?(operator) && expression.key?("value")

  value = expression["value"]
  case operator
  when "in"
    value.is_a?(Array) && value.length.between?(1, 100) && value.uniq.length == value.length &&
      value.all? { |item| scalar_valid?(definition["type"], item) }
  when "exists"
    [true, false].include?(value)
  else
    scalar_valid?(definition["type"], value)
  end
end

def comparable(type, value)
  case type
  when "decimal" then Rational(value)
  when "date" then Date.iso8601(value)
  when "date-time" then Time.iso8601(value).utc
  else value
  end
end

def expression_matches?(definition, expression, values)
  return false unless expression_valid?(definition, expression)
  return expression["value"] ? !values.empty? : values.empty? if expression["operator"] == "exists"

  typed_values = values.map { |value| comparable(definition["type"], value) }
  requested = expression["value"]
  case expression["operator"]
  when "eq" then typed_values.include?(comparable(definition["type"], requested))
  when "in"
    accepted = requested.map { |value| comparable(definition["type"], value) }
    !(typed_values & accepted).empty?
  when "lt" then typed_values.any? { |value| value < comparable(definition["type"], requested) }
  when "lte" then typed_values.any? { |value| value <= comparable(definition["type"], requested) }
  when "gt" then typed_values.any? { |value| value > comparable(definition["type"], requested) }
  when "gte" then typed_values.any? { |value| value >= comparable(definition["type"], requested) }
  end
end

def sort_valid?(sort, definitions)
  return false unless sort.is_a?(Hash) && %w[id title description keys].all? { |field| sort.key?(field) }
  return false unless sort["id"].is_a?(String) && sort["id"].match?(IDENTIFIER)
  return false unless sort["title"].is_a?(String) && sort["title"].length.between?(1, 128)
  return false unless sort["description"].is_a?(String) && sort["description"].length.between?(1, 1024)

  keys = sort["keys"]
  return false unless keys.is_a?(Array) && keys.length.between?(1, 3)
  filter_ids = keys.map { |key| key["filter_id"] }
  return false unless filter_ids.uniq.length == filter_ids.length

  available = definitions.map { |definition| definition["id"] }
  keys.all? do |key|
    available.include?(key["filter_id"]) && %w[ascending descending].include?(key["direction"]) &&
      %w[first last].include?(key["missing"])
  end
end

path = Pathname.new(__dir__).join("..", "test-vectors", "filters-sorting", "contract.json").expand_path
vector = JSON.parse(path.read)
errors = vector.fetch("cases").filter_map do |test_case|
  actual = case test_case.fetch("operation")
           when "validate-definition"
             definition_valid?(test_case.fetch("definition"))
           when "validate-expression"
             expression_valid?(test_case.fetch("definition"), test_case.fetch("expression"))
           when "evaluate-expression"
             expression_matches?(test_case.fetch("definition"), test_case.fetch("expression"), test_case.fetch("values"))
           when "validate-sort"
             sort_valid?(test_case.fetch("sort"), test_case.fetch("definitions"))
           else
             :unknown
           end
  if actual == :unknown
    "#{path}: unknown operation #{test_case['operation']}"
  elsif actual != test_case.fetch("valid")
    "#{path}: #{test_case.fetch('name')} mismatch"
  end
end

if errors.empty?
  puts "Filter and sorting vectors OK"
else
  warn errors.join("\n")
  exit 1
end
