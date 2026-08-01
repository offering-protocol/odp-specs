#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"

DEFAULTS = {
  "list-collections" => "terse",
  "search-collections" => "terse",
  "get-collection" => "full",
  "list-collection-offerings" => "terse",
  "list-offerings" => "terse",
  "search-offerings" => "terse",
  "get-offering" => "full"
}.freeze
POINTER = /\A(?:\/(?:[\x20-\x2E\x30-\x7D]|~[01])*)+\z/
INHERITED_FIELDS = ["odp_version"].freeze

def escape_token(token)
  token.gsub("~", "~0").gsub("/", "~1")
end

def omitted_fields(terse, full, path = "")
  return [] unless terse.is_a?(Hash) && full.is_a?(Hash)

  full.each_with_object([]) do |(key, value), pointers|
    next if path.empty? && (INHERITED_FIELDS.include?(key) || key == "detail_fields")

    pointer = "#{path}/#{escape_token(key)}"
    if !terse.key?(key)
      pointers << pointer
    elsif terse[key].is_a?(Hash) && value.is_a?(Hash)
      pointers.concat(omitted_fields(terse[key], value, pointer))
    end
  end
end

def common_field_types_match?(terse, full)
  terse.all? do |key, value|
    next true if key == "detail_fields" || !full.key?(key)

    full_value = full[key]
    value.class == full_value.class && (!value.is_a?(Hash) || common_field_types_match?(value, full_value))
  end
end

def valid_detail_fields?(terse, full)
  return false unless terse["id"].is_a?(String) && terse["name"].is_a?(String)
  return false unless full["id"] == terse["id"] && full["name"].is_a?(String)
  return false unless common_field_types_match?(terse, full)

  fields = terse["detail_fields"]
  return !full.key?("detail_fields") if fields.nil?
  return false if full.key?("detail_fields")
  return false unless fields.is_a?(Array) && fields.length.between?(1, 32) && fields.uniq.length == fields.length
  return false unless fields.all? { |field| field.is_a?(String) && field.ascii_only? && field.length <= 256 && field.match?(POINTER) }

  fields.sort == omitted_fields(terse.reject { |key, _| key == "detail_fields" }, full).sort
end

root = Pathname.new(__dir__).join("..", "test-vectors", "representation").expand_path
errors = []

Dir[root.join("*.json")].sort.each do |path|
  vector = JSON.parse(Pathname.new(path).read)
  vector.fetch("cases").each do |test_case|
    actual = case vector.fetch("subject")
             when "representation-selection"
               values = test_case.fetch("representation", [])
               if values.length > 1 || (values.length == 1 && !%w[terse full].include?(values.first))
                 "400"
               else
                 values.first || DEFAULTS.fetch(test_case.fetch("operation"))
               end
             when "detail-fields"
               valid_detail_fields?(test_case.fetch("terse"), test_case.fetch("full"))
             else
               errors << "#{path}: unknown subject #{vector['subject']}"
               next
             end
    expected = test_case.key?("valid") ? test_case.fetch("valid") : test_case.fetch("expected")
    errors << "#{path}: #{test_case.fetch('name')} mismatch" unless actual == expected
  end
end

examples = Pathname.new(__dir__).join("..", "examples", "marketplace").expand_path
search = JSON.parse(examples.join("home-office-search-response.json").read)
full = JSON.parse(examples.join("walnut-standing-desk-offering.json").read)
terse = search.fetch("items").find { |item| item["id"] == full["id"] }
errors << "marketplace example: missing matching terse Offering" unless terse
if terse && !valid_detail_fields?(terse, full)
  errors << "marketplace example: detail_fields do not exhaustively describe the matching Full Representation"
end

if errors.empty?
  puts "Representation vectors OK"
else
  warn errors.join("\n")
  exit 1
end
