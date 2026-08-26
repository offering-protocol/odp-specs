#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"
require_relative "odp_identity"

DRAFT_2020_12 = "https://json-schema.org/draft/2020-12/schema"

def reference_valid?(reference)
  reference.is_a?(Hash) && reference.keys == ["url"] && OdpIdentity.resource_reference?(reference["url"])
end

def response_valid?(test_case)
  media_type = test_case.fetch("content_type").split(";", 2).first.strip.downcase
  document = test_case.fetch("document")
  test_case.fetch("status").between?(200, 299) && media_type == "application/schema+json" &&
    document.is_a?(Hash) && document["$schema"] == DRAFT_2020_12
end

def dynamic_references_valid?(value)
  case value
  when Array
    value.all? { |item| dynamic_references_valid?(item) }
  when Hash
    dynamic_reference = value["$dynamicRef"]
    (!value.key?("$dynamicRef") ||
      (dynamic_reference.is_a?(String) && dynamic_reference.start_with?("#"))) &&
      value.values.all? { |item| dynamic_references_valid?(item) }
  else
    true
  end
end

def evaluate(test_case)
  case test_case.fetch("operation")
  when "validate-reference"
    reference_valid?(test_case.fetch("reference"))
  when "validate-response"
    response_valid?(test_case)
  when "validation-scope"
    test_case.fetch("representation") == "full"
  when "failure-scope"
    {
      "offering_usable" => true,
      "attributes_usable" => false,
      "report_issue" => true
    }
  when "validate-schema-reference-profile"
    test_case.fetch("documents").all? { |document| dynamic_references_valid?(document) }
  end
end

path = Pathname.new(__dir__).join("..", "test-vectors", "attribute-schemas", "retrieval.json").expand_path
vector = JSON.parse(path.read)
errors = vector.fetch("cases").filter_map do |test_case|
  expected = test_case.key?("valid") ? test_case.fetch("valid") :
    test_case.fetch("complete_instance_validation", test_case["expected"])
  actual = evaluate(test_case)
  "#{path}: #{test_case.fetch('name')} mismatch" unless actual == expected
end

if errors.empty?
  puts "Attribute Schema vectors OK"
else
  warn errors.join("\n")
  exit 1
end
