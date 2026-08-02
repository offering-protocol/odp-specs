#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"
require_relative "odp_identity"

RELATION = /\A[a-z][a-z0-9]*(?:-[a-z0-9]+)*\z/
COMMON_KEYS = %w[id rel description http openapi].freeze
HTTP_KEYS = %w[href method request response_content_types].freeze
REQUEST_KEYS = %w[content_type schema].freeze
OPENAPI_KEYS = %w[url operation_id].freeze

def non_empty_string?(value, maximum)
  value.is_a?(String) && !value.empty? && value.length <= maximum
end

def request_valid?(request)
  return false unless request.is_a?(Hash) && !request.empty? && (request.keys - REQUEST_KEYS).empty?
  return false if request.key?("content_type") && !non_empty_string?(request["content_type"], 255)
  return true unless request.key?("schema")

  schema = request["schema"]
  schema.is_a?(Hash) && schema.keys == ["url"] && OdpIdentity.resource_reference?(schema["url"])
end

def http_valid?(target)
  return false unless target.is_a?(Hash) && (target.keys - HTTP_KEYS).empty?
  return false unless OdpIdentity.resource_reference?(target["href"])
  return false unless %w[GET POST].include?(target["method"])
  return false if target.key?("request") && !request_valid?(target["request"])
  return true unless target.key?("response_content_types")

  types = target["response_content_types"]
  types.is_a?(Array) && types.length.between?(1, 8) && types.uniq.length == types.length &&
    types.all? { |value| non_empty_string?(value, 255) }
end

def openapi_valid?(target)
  target.is_a?(Hash) && (target.keys - OPENAPI_KEYS).empty? && target.keys.sort == OPENAPI_KEYS.sort &&
    OdpIdentity.resource_reference?(target["url"]) && non_empty_string?(target["operation_id"], 128)
end

def action_valid?(action)
  return false unless action.is_a?(Hash) && (action.keys - COMMON_KEYS).empty?
  return false unless OdpIdentity.local_identifier?(action["id"])
  return false unless non_empty_string?(action["rel"], 64) && action["rel"].match?(RELATION)
  return false if action.key?("description") && !non_empty_string?(action["description"], 512)

  targets = %w[http openapi].select { |key| action.key?(key) }
  return false unless targets.length == 1

  targets.first == "http" ? http_valid?(action["http"]) : openapi_valid?(action["openapi"])
end

def validate_actions(actions)
  return { "usable" => [], "issues" => [nil] } unless actions.is_a?(Array) && actions.length.between?(1, 16)

  duplicate_ids = actions.filter_map { |action| action["id"] if action.is_a?(Hash) }
                         .tally.select { |_id, count| count > 1 }.keys
  issues = []
  usable = actions.filter_map do |action|
    identifier = action.is_a?(Hash) ? action["id"] : nil
    if duplicate_ids.include?(identifier) || !action_valid?(action)
      issues << identifier
      nil
    else
      identifier
    end
  end
  { "usable" => usable, "issues" => issues }
end

def openapi_resolves?(target, document)
  return false unless openapi_valid?(target) && document.is_a?(Hash)
  return false unless document["openapi"].is_a?(String) && document["openapi"].match?(/\A3\.1(?:\.|\z)/)

  Array(document["operation_ids"]).count(target["operation_id"]) == 1
end

path = Pathname.new(__dir__).join("..", "test-vectors", "actions", "contract.json").expand_path
vector = JSON.parse(path.read)
errors = vector.fetch("cases").filter_map do |test_case|
  actual = case test_case.fetch("operation")
           when "validate-actions"
             validate_actions(test_case.fetch("actions"))
           when "resolve-openapi"
             openapi_resolves?(test_case.fetch("target"), test_case.fetch("document"))
           end
  expected = if test_case.fetch("operation") == "validate-actions"
               { "usable" => test_case.fetch("expected_usable"), "issues" => test_case.fetch("expected_issues") }
             else
               test_case.fetch("valid")
             end
  "#{path}: #{test_case.fetch('name')} mismatch" unless actual == expected
end

examples_root = Pathname.new(__dir__).join("..", "examples").expand_path
Dir[examples_root.join("**/*-offering.json")].sort.each do |name|
  example_path = Pathname.new(name)
  document = JSON.parse(example_path.read)
  next unless document.key?("actions")

  result = validate_actions(document["actions"])
  next if result["issues"].empty? && result["usable"].length == document["actions"].length

  errors << "#{example_path}: invalid or duplicate Action"
end

if errors.empty?
  puts "Action vectors OK"
else
  warn errors.join("\n")
  exit 1
end
