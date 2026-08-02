#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"
require_relative "odp_identity"

MAXIMUM_DEPTH = 32
LANGUAGE_TAG = /\A[A-Za-z]{2,8}(?:-[A-Za-z0-9]{1,8})*\z/

def valid_identifiers?(values)
  values.is_a?(Array) && values.uniq.length == values.length &&
    values.all? { |value| OdpIdentity.local_identifier?(value) }
end

def valid_non_empty_identifiers?(values)
  valid_identifiers?(values) && !values.empty?
end

def hierarchy_valid?(collections)
  return false unless collections.is_a?(Array)

  identifiers = collections.map { |collection| collection["id"] }
  return false unless valid_identifiers?(identifiers)
  return false unless collections.all? do |collection|
    !collection.key?("parent_ids") || valid_non_empty_identifiers?(collection["parent_ids"])
  end

  parents = collections.to_h { |collection| [collection.fetch("id"), collection.fetch("parent_ids", [])] }
  return false unless parents.all? { |id, values| !values.include?(id) && values.all? { |parent| parents.key?(parent) } }

  depth = lambda do |identifier, visiting, memo|
    return memo[identifier] if memo.key?(identifier)
    return nil if visiting.include?(identifier)

    next_visiting = visiting + [identifier]
    parent_depths = parents.fetch(identifier).map { |parent| depth.call(parent, next_visiting, memo) }
    return nil if parent_depths.any?(&:nil?)

    memo[identifier] = parent_depths.empty? ? 0 : parent_depths.max + 1
  end

  memo = {}
  parents.keys.all? do |identifier|
    value = depth.call(identifier, [], memo)
    value && value <= MAXIMUM_DEPTH
  end
end

def generated_chain(length)
  (0..length).map do |index|
    {
      "id" => "collection-#{index}",
      **(index.zero? ? {} : { "parent_ids" => ["collection-#{index - 1}"] })
    }
  end
end

def collection_document_valid?(document)
  required = %w[odp_version id name]
  return false unless document.is_a?(Hash) && required.all? { |field| document.key?(field) }
  return false unless document["odp_version"] == "1.0" && OdpIdentity.local_identifier?(document["id"])
  return false unless document["name"].is_a?(String) && !document["name"].empty?
  return false if document.key?("description") &&
    (!document["description"].is_a?(String) || document["description"].empty?)

  if document.key?("language")
    language = document["language"]
    return false unless language.is_a?(String) && language.match?(LANGUAGE_TAG)
  end
  if document.key?("localizations")
    localizations = document["localizations"]
    return false unless localizations.is_a?(Array) && !localizations.empty?
    return false unless localizations.all? { |tag| tag.is_a?(String) && tag.match?(LANGUAGE_TAG) }
    folded = localizations.map(&:downcase)
    return false unless folded.uniq.length == folded.length
    return false if document.key?("language") && !folded.include?(document["language"].downcase)
  end

  !document.key?("parent_ids") || valid_non_empty_identifiers?(document["parent_ids"])
end

def membership_result(test_case)
  collections = test_case.fetch("collections")
  return nil unless valid_identifiers?(collections)

  offerings = test_case.fetch("offerings")
  valid = offerings.all? do |offering|
    memberships = offering.fetch("collection_ids", [])
    OdpIdentity.local_identifier?(offering["id"]) &&
      (!offering.key?("collection_ids") || valid_non_empty_identifiers?(memberships)) &&
      memberships.all? { |identifier| collections.include?(identifier) }
  end
  return nil unless valid

  offerings.filter_map do |offering|
    offering["id"] if offering.fetch("collection_ids", []).include?(test_case.fetch("query_collection_id"))
  end
end

root = Pathname.new(__dir__).join("..", "test-vectors", "collections").expand_path
errors = []

Dir[root.join("*.json")].sort.each do |path|
  vector = JSON.parse(Pathname.new(path).read)
  vector.fetch("cases").each do |test_case|
    actual = case vector.fetch("subject")
             when "collection-envelope"
               collection_document_valid?(test_case.fetch("document"))
             when "collection-hierarchy"
               collections = test_case["collections"] || generated_chain(test_case.fetch("chain_length"))
               hierarchy_valid?(collections)
             when "collection-membership"
               result = membership_result(test_case)
               test_case.key?("valid") ? !result.nil? : result
             when "invalid-edge-handling"
               %w[cycle depth-exceeded missing-parent missing-collection].include?(test_case["condition"]) ?
                 "ignore-edge" : "unknown-condition"
             else
               errors << "#{path}: unknown subject #{vector['subject']}"
               next
             end
    expected = if test_case.key?("valid")
                 test_case.fetch("valid")
               elsif test_case.key?("offering_ids")
                 test_case.fetch("offering_ids")
               else
                 test_case.fetch("expected")
               end
    errors << "#{path}: #{test_case.fetch('name')} mismatch" unless actual == expected
  end
end

example_path = Pathname.new(__dir__).join("..", "examples", "marketplace", "home-office-collection.json")
example = JSON.parse(example_path.read)
errors << "#{example_path}: invalid Full Collection" unless collection_document_valid?(example)

if errors.empty?
  puts "Collection vectors OK"
else
  warn errors.join("\n")
  exit 1
end
