#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"

SERVICE_OPERATIONS = %w[list-offerings get-offering].freeze
AGENT_BEHAVIORS = %w[
  inspect-service
  list-offerings
  follow-pagination
  get-offering
  process-representations
  process-localization
  honor-caching
  handle-errors-and-limits
  enforce-redirect-and-security
  enforce-compatibility
].freeze

def offering_valid?(offering, full:)
  return false unless offering.is_a?(Hash)
  return false unless offering["id"].is_a?(String) && !offering["id"].empty?
  return false unless offering["name"].is_a?(String) && !offering["name"].empty?

  !full || offering["odp_version"] == "1.0"
end

def service_valid?(test_case)
  operations = test_case.fetch("operations")
  return false unless operations.is_a?(Array) && SERVICE_OPERATIONS.all? { |operation| operations.include?(operation) }

  list_response = test_case.fetch("list_response")
  return false unless list_response.is_a?(Hash) && list_response["odp_version"] == "1.0"
  return false unless list_response["items"].is_a?(Array)
  return false unless list_response["items"].all? { |offering| offering_valid?(offering, full: false) }

  offering_valid?(test_case.fetch("get_response"), full: true)
end

def agent_valid?(test_case)
  behaviors = test_case.fetch("behaviors")
  behaviors.is_a?(Array) && AGENT_BEHAVIORS.all? { |behavior| behaviors.include?(behavior) }
end

path = Pathname.new(__dir__).join("..", "test-vectors", "conformance", "baseline.json").expand_path
vector = JSON.parse(path.read)
errors = vector.fetch("cases").filter_map do |test_case|
  actual = case test_case.fetch("role")
           when "service" then service_valid?(test_case)
           when "agent" then agent_valid?(test_case)
           else false
           end
  "#{path}: #{test_case.fetch('name')} validity mismatch" unless actual == test_case.fetch("valid")
end

if errors.empty?
  puts "Conformance vectors OK"
else
  warn errors.join("\n")
  exit 1
end
