#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"
require_relative "odp_identity"

def request_valid?(request)
  return false unless request.is_a?(Hash) && request["odp_version"] == "1.0"
  return false unless request.key?("query") || request.key?("parent_id")

  if request.key?("query")
    query = request["query"]
    return false unless query.is_a?(String) && query.length.between?(1, 256) && query.match?(/\S/)
  end

  if request.key?("parent_id")
    parent_id = request["parent_id"]
    return false unless parent_id.nil? || OdpIdentity.local_identifier?(parent_id)
  end

  !request.key?("limit") || request["limit"].is_a?(Integer) && request["limit"].between?(1, 100)
end

def apply_constraints(test_case)
  request = test_case.fetch("request")
  return nil unless request_valid?(request)

  matches = test_case.fetch("service_matches")
  collections = test_case.fetch("collections").to_h { |collection| [collection.fetch("id"), collection] }
  matches.filter do |identifier|
    collection = collections.fetch(identifier)
    next true unless request.key?("parent_id")

    parent_id = request["parent_id"]
    parent_id.nil? ? !collection.key?("parent_ids") : collection.fetch("parent_ids", []).include?(parent_id)
  end
end

path = Pathname.new(__dir__).join("..", "test-vectors", "collection-search", "contract.json").expand_path
vector = JSON.parse(path.read)
errors = vector.fetch("cases").filter_map do |test_case|
  actual = case test_case.fetch("operation")
           when "validate-request"
             request_valid?(test_case.fetch("request"))
           when "apply-constraints"
             apply_constraints(test_case)
           end
  expected = test_case.key?("valid") ? test_case.fetch("valid") : test_case.fetch("collection_ids")
  "#{path}: #{test_case.fetch('name')} mismatch" unless actual == expected
end

if errors.empty?
  puts "Collection search vectors OK"
else
  warn errors.join("\n")
  exit 1
end
