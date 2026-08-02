#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"
require "uri"
require_relative "odp_identity"

def page_valid?(page)
  page.is_a?(Hash) && page["odp_version"] == "1.0" && page["items"].is_a?(Array) &&
    !page.key?("next_cursor") &&
    (!page.key?("next") || OdpIdentity.resource_reference?(page["next"]) && page["next"].bytesize <= 2048)
end

def same_origin_next?(service_origin, reference)
  return false unless OdpIdentity.canonical_origin?(service_origin) && OdpIdentity.resource_reference?(reference)

  resolved = URI.join("#{service_origin}/", reference)
  origin = URI.parse(service_origin)
  resolved.scheme == origin.scheme && resolved.host == origin.host && resolved.port == origin.port
end

def evaluate(test_case)
  case test_case.fetch("operation")
  when "validate-page"
    page_valid?(test_case.fetch("page"))
  when "validate-limit"
    test_case["limit"].is_a?(Integer) && test_case["limit"].between?(1, 100)
  when "validate-sequence"
    identifiers = test_case.fetch("pages").flatten
    identifiers.uniq.length == identifiers.length
  when "validate-next"
    test_case.fetch("method") == "GET" &&
      same_origin_next?(test_case.fetch("service_origin"), test_case.fetch("next"))
  when "validate-lifetime"
    test_case.fetch("lifetime_seconds") >= 3600
  when "validate-storage-model"
    %w[stateful stateless].include?(test_case.fetch("storage_model"))
  when "conditional-get"
    test_case.fetch("method") == "GET" && test_case.fetch("validator_matches") && test_case.fetch("status") == 304
  end
end

path = Pathname.new(__dir__).join("..", "test-vectors", "pagination", "contract.json").expand_path
vector = JSON.parse(path.read)
errors = vector.fetch("cases").filter_map do |test_case|
  actual = evaluate(test_case)
  "#{path}: #{test_case.fetch('name')} mismatch" unless actual == test_case.fetch("valid")
end

if errors.empty?
  puts "Pagination vectors OK"
else
  warn errors.join("\n")
  exit 1
end
