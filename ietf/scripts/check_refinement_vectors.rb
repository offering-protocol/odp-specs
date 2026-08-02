#!/usr/bin/env ruby
# frozen_string_literal: true

require "date"
require "json"
require "pathname"
require "time"

IDENTIFIER = /\A[A-Za-z0-9._~-]{1,64}\z/
DECIMAL = /\A-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?\z/
MAXIMUM_COUNT = 9_007_199_254_740_991

def scalar_valid?(type, value)
  case type
  when "string" then value.is_a?(String)
  when "boolean" then [true, false].include?(value)
  when "integer" then value.is_a?(Integer)
  when "number" then value.is_a?(Numeric)
  when "decimal" then value.is_a?(String) && value.match?(DECIMAL)
  when "date" then value.is_a?(String) && Date.iso8601(value).to_s == value
  when "date-time" then value.is_a?(String) && !Time.iso8601(value).nil?
  else false
  end
rescue Date::Error, ArgumentError
  false
end

def refinement_request_valid?(request, definitions)
  identifiers = request["refinements"]
  return false unless identifiers.is_a?(Array) && identifiers.length.between?(1, 16)
  return false unless identifiers.uniq.length == identifiers.length &&
    identifiers.all? { |id| id.is_a?(String) && id.match?(IDENTIFIER) }

  available = definitions.to_h { |definition| [definition["id"], definition] }
  identifiers.all? do |identifier|
    definition = available[identifier]
    definition && definition["refinable"] == true && !(Array(definition["operators"]) & %w[eq in]).empty?
  end
end

def refinement_response_valid?(response, request, definitions, continuation)
  refinements = response["refinements"]
  return refinements.nil? if continuation || !request.key?("refinements")
  return true if refinements.nil?
  return false unless refinements.is_a?(Array) && refinements.length.between?(1, 16)

  filter_ids = refinements.filter_map { |group| group["filter_id"] if group.is_a?(Hash) }
  return false unless filter_ids.length == refinements.length && filter_ids.uniq.length == filter_ids.length

  available = definitions.to_h { |definition| [definition["id"], definition] }
  refinements.all? do |group|
    definition = available[group["filter_id"]]
    values = group["values"]
    next false unless request.fetch("refinements").include?(group["filter_id"]) && definition
    next false unless values.is_a?(Array) && values.length.between?(1, 32)
    next false unless values.map { |bucket| JSON.generate(bucket["value"]) }.uniq.length == values.length

    values.all? do |bucket|
      bucket.is_a?(Hash) && scalar_valid?(definition["type"], bucket["value"]) &&
        bucket["count"].is_a?(Integer) && bucket["count"].between?(0, MAXIMUM_COUNT) &&
        (!bucket.key?("count_relation") || bucket["count_relation"] == "lower_bound")
    end
  end
end

def expression_matches?(expression, mapped_values)
  case expression["operator"]
  when "eq" then mapped_values.include?(expression["value"])
  when "in" then !(mapped_values & expression["value"]).empty?
  when "exists" then expression["value"] ? !mapped_values.empty? : mapped_values.empty?
  else true
  end
end

def compute_counts(test_case)
  filter_id = test_case.fetch("filter_id")
  filters = test_case.fetch("request").fetch("filters", []).reject { |expression| expression["id"] == filter_id }
  test_case.fetch("values").to_h do |candidate|
    matching_ids = test_case.fetch("service_matches").filter_map do |offering|
      mapped = offering.fetch("mapped_values", {})
      next unless filters.all? { |expression| expression_matches?(expression, mapped.fetch(expression["id"], [])) }
      next unless mapped.fetch(filter_id, []).include?(candidate)

      offering.fetch("id")
    end
    [candidate, matching_ids.uniq.length]
  end
end

path = Pathname.new(__dir__).join("..", "test-vectors", "refinements", "contract.json").expand_path
vector = JSON.parse(path.read)
errors = vector.fetch("cases").filter_map do |test_case|
  actual = case test_case.fetch("operation")
           when "validate-request"
             refinement_request_valid?(test_case.fetch("request"), test_case.fetch("definitions"))
           when "validate-response"
             refinement_response_valid?(test_case.fetch("response"), test_case.fetch("request"),
                                         test_case.fetch("definitions"), test_case.fetch("continuation", false))
           when "compute-counts"
             compute_counts(test_case)
           else
             :unknown
           end
  expected = test_case.key?("valid") ? test_case.fetch("valid") : test_case.fetch("expected")
  if actual == :unknown
    "#{path}: unknown operation #{test_case['operation']}"
  elsif actual != expected
    "#{path}: #{test_case.fetch('name')} mismatch"
  end
end

if errors.empty?
  puts "Refinement vectors OK"
else
  warn errors.join("\n")
  exit 1
end
