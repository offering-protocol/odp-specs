#!/usr/bin/env ruby
# frozen_string_literal: true

require "bigdecimal"
require "json"
require "pathname"
require_relative "odp_identity"
require_relative "odp_image"

KNOWN_PRICE_TYPES = %w[free fixed range starting_at metered quote].freeze
DECIMAL = /\A(?:0|[1-9][0-9]*)(?:\.[0-9]+)?\z/

def decimal?(value)
  value.is_a?(String) && value.match?(DECIMAL)
end

def price_valid?(price)
  return false unless price.is_a?(Hash) && price["type"].is_a?(String) && !price["type"].empty?
  return true unless KNOWN_PRICE_TYPES.include?(price["type"])

  case price["type"]
  when "free", "quote"
    true
  when "fixed", "starting_at"
    decimal?(price["amount"]) && price["currency"].is_a?(String) && !price["currency"].empty?
  when "range"
    decimal?(price["minimum"]) && decimal?(price["maximum"]) &&
      BigDecimal(price["minimum"]) <= BigDecimal(price["maximum"]) &&
      price["currency"].is_a?(String) && !price["currency"].empty?
  when "metered"
    decimal?(price["amount"]) && price["currency"].is_a?(String) && !price["currency"].empty? &&
      price["unit"].is_a?(String) && !price["unit"].empty?
  end
end

def offering_valid?(document, representation)
  return false unless document.is_a?(Hash)
  return false unless %w[id name].all? { |field| document[field].is_a?(String) && !document[field].empty? }
  return false unless OdpIdentity.local_identifier?(document["id"])
  return false if representation == "full" && document["odp_version"] != "1.0"
  return false if representation == "terse" && document.key?("actions")
  return false if document.key?("collection_ids") &&
    (!document["collection_ids"].is_a?(Array) || document["collection_ids"].empty? ||
      document["collection_ids"].uniq.length != document["collection_ids"].length ||
      !document["collection_ids"].all? { |id| OdpIdentity.local_identifier?(id) })
  return false if document.key?("attributes") &&
    (!document["attributes"].is_a?(Hash) || document["attributes"].empty? || !document.key?("schema"))
  return false if document.key?("actions") &&
    (!document["actions"].is_a?(Array) || document["actions"].empty?)
  return false if document.key?("price") && !price_valid?(document["price"])
  return false if document.key?("images") && !OdpImage.list?(document["images"])

  true
end

path = Pathname.new(__dir__).join("..", "test-vectors", "offerings", "contract.json").expand_path
vector = JSON.parse(path.read)
errors = vector.fetch("cases").filter_map do |test_case|
  actual = offering_valid?(test_case.fetch("document"), test_case.fetch("representation"))
  "#{path}: #{test_case.fetch('name')} mismatch" unless actual == test_case.fetch("valid")
end

if errors.empty?
  puts "Offering vectors OK"
else
  warn errors.join("\n")
  exit 1
end
