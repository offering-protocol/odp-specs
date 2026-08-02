#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"
require_relative "odp_versioning"

REQUIRED_METADATA = %w[id title description drafts category applies_to subject cases].freeze

def expected_media_result(test_case)
  return "serve-odp" if test_case["accept_missing"]
  return test_case["accepts_odp"] || test_case["accepts_wildcard"] ? "serve-odp" : "406" if test_case.key?("accepts_odp") || test_case.key?("accepts_wildcard")
  return "415" if test_case["request_content_type_missing"]
  return test_case["request_content_type_essence"] == "application/odp+json" ? "process" : "415" if test_case.key?("request_content_type_essence")
  return test_case["response_content_type_essence"] == "application/odp+json" ? "process" : "reject" if test_case.key?("response_content_type_essence")

  nil
end

root = Pathname.new(__dir__).join("..", "test-vectors", "versioning").expand_path
errors = []

Dir[root.join("*.json")].sort.each do |path|
  vector = JSON.parse(Pathname.new(path).read)
  missing = REQUIRED_METADATA.reject { |field| vector.key?(field) }
  errors << "#{path}: missing metadata: #{missing.join(', ')}" unless missing.empty?

  vector.fetch("cases").each do |test_case|
    case vector.fetch("subject")
    when "protocol-version"
      received = OdpVersioning.parse(test_case.fetch("received"))
      supported = OdpVersioning.parse(test_case.fetch("supported"))
      valid = !received.nil?
      compatible = OdpVersioning.compatible?(test_case.fetch("supported"), test_case.fetch("received"))
      errors << "#{path}: #{test_case.fetch('name')} validity mismatch" unless valid == test_case.fetch("valid")
      errors << "#{path}: #{test_case.fetch('name')} compatibility mismatch" unless compatible == test_case.fetch("compatible")
    when "version-placement"
      valid = test_case.fetch("top_level") == test_case.fetch("odp_version_present")
      errors << "#{path}: #{test_case.fetch('name')} placement mismatch" unless valid == test_case.fetch("valid")
    when "media-negotiation"
      actual = expected_media_result(test_case)
      expected = test_case["response"] || test_case["agent"]
      errors << "#{path}: #{test_case.fetch('name')} negotiation mismatch" unless actual == expected
      if test_case.key?("effective_odp_version")
        errors << "#{path}: #{test_case.fetch('name')} body version must be authoritative" unless test_case["effective_odp_version"] == test_case["body_odp_version"]
      end
    else
      errors << "#{path}: unknown subject #{vector['subject']}"
    end
  end
end

if errors.empty?
  puts "Versioning vectors OK"
else
  warn errors.join("\n")
  exit 1
end
