#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"
require_relative "odp_identity"

MAXIMUM_DEPTH = 32

def request_valid?(request)
  return false unless request.is_a?(Hash) && request["odp_version"] == "1.0"

  return false unless request.key?("query") || request.key?("filters")
  if request.key?("query")
    query = request["query"]
    return false unless query.is_a?(String) && query.length.between?(1, 256) && query.match?(/\S/)
  end
  if request.key?("filters")
    filters = request["filters"]
    return false unless filters.is_a?(Array) && filters.length.between?(1, 32) && filters.all?(Hash)
  end
  return false if request.key?("sort") &&
    (!request["sort"].is_a?(String) || !request["sort"].match?(/\A[A-Za-z0-9._~-]{1,64}\z/))
  if request.key?("refinements")
    refinements = request["refinements"]
    return false unless refinements.is_a?(Array) && refinements.length.between?(1, 16) &&
      refinements.uniq.length == refinements.length &&
      refinements.all? { |identifier| identifier.is_a?(String) && identifier.match?(/\A[A-Za-z0-9._~-]{1,64}\z/) }
  end
  return false if request.key?("collection_id") && !OdpIdentity.local_identifier?(request["collection_id"])
  if request.key?("include_descendants")
    return false unless [true, false].include?(request["include_descendants"]) && request.key?("collection_id")
  end

  !request.key?("limit") || request["limit"].is_a?(Integer) && request["limit"].between?(1, 100)
end

def descendants(collection_id, collections)
  children = Hash.new { |hash, key| hash[key] = [] }
  collections.each do |collection|
    collection.fetch("parent_ids", []).each { |parent_id| children[parent_id] << collection.fetch("id") }
  end

  included = [collection_id]
  queue = [[collection_id, 0]]
  until queue.empty?
    current, depth = queue.shift
    next if depth >= MAXIMUM_DEPTH

    children[current].each do |child|
      next if included.include?(child)

      included << child
      queue << [child, depth + 1]
    end
  end
  included
end

def apply_constraints(test_case)
  request = test_case.fetch("request")
  return nil unless request_valid?(request)

  collections = test_case.fetch("collections")
  collection_ids = collections.map { |collection| collection.fetch("id") }
  scope = request["collection_id"]
  return "not-found" if scope && !collection_ids.include?(scope)

  included = if scope
               request.fetch("include_descendants", false) ? descendants(scope, collections) : [scope]
             end
  seen = []
  test_case.fetch("service_matches").filter_map do |offering|
    next if included && (offering.fetch("collection_ids", []) & included).empty?
    next if seen.include?(offering.fetch("id"))

    seen << offering.fetch("id")
    offering.fetch("id")
  end
end

path = Pathname.new(__dir__).join("..", "test-vectors", "offering-search", "contract.json").expand_path
vector = JSON.parse(path.read)
errors = vector.fetch("cases").filter_map do |test_case|
  actual = case test_case.fetch("operation")
           when "validate-request"
             request_valid?(test_case.fetch("request"))
           when "apply-constraints"
             apply_constraints(test_case)
           end
  expected = test_case.key?("valid") ? test_case.fetch("valid") : test_case.fetch("expected")
  "#{path}: #{test_case.fetch('name')} mismatch" unless actual == expected
end

if errors.empty?
  puts "Offering search vectors OK"
else
  warn errors.join("\n")
  exit 1
end
