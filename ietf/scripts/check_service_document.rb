#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"
require_relative "odp_identity"

OPERATIONS = %w[
  list-collections search-collections get-collection list-collection-offerings
  list-offerings search-offerings get-offering
].freeze
AUTHENTICATION_REQUIREMENTS = %w[not-required optional required].freeze
LANGUAGE_TAG = /\A[A-Za-z]{2,8}(?:-[A-Za-z0-9]{1,8})*\z/
ENDPOINT_BASE = %r{\A/(?!/)[A-Za-z0-9._~!$&'()*+,;=:@%/-]*\z}

def capability_source_valid?(source, maximum)
  return false unless source.is_a?(Hash)

  forms = %w[inline linked].select { |field| source.key?(field) }
  return false unless forms.length == 1

  if source.key?("inline")
    source["inline"].is_a?(Array) && source["inline"].length.between?(1, maximum)
  else
    linked = source["linked"]
    linked.is_a?(Hash) && OdpIdentity.resource_reference?(linked["href"])
  end
end

def search_capabilities_valid?(capabilities, operation_names)
  return false unless capabilities.is_a?(Hash) && (capabilities.key?("filters") || capabilities.key?("sorts"))
  return false unless operation_names.include?("search-offerings")
  return false if capabilities.key?("filters") && !capability_source_valid?(capabilities["filters"], 32)
  return false if capabilities.key?("sorts") && !capability_source_valid?(capabilities["sorts"], 16)

  true
end

def protocols_valid?(protocols)
  return false unless protocols.is_a?(Hash) && !protocols.empty?
  return false unless (protocols.keys - %w[enrollment payments]).empty?

  enrollment = protocols["enrollment"]
  return false if enrollment && enrollment != [{ "name" => "aep" }]
  payments = protocols["payments"]
  return false if protocols.key?("payments") &&
    (!payments.is_a?(Array) || payments.empty? || payments.length > 2 ||
      payments.any? do |payment|
        !payment.is_a?(Hash) || (payment.keys - %w[authentication name]).any? ||
          !%w[authentication name].all? { |key| payment.key?(key) } ||
          !%w[not-required required].include?(payment["authentication"]) || !%w[mpp x402].include?(payment["name"])
      end || payments.map { |payment| payment["name"] }.uniq.length != payments.length)

  return false if payments&.any? { |payment| payment["authentication"] == "required" } && enrollment.nil?

  true
end

def operations_valid?(operations)
  return false unless operations.is_a?(Array) && operations.length.between?(2, OPERATIONS.length)
  return false if operations.any? do |operation|
    !operation.is_a?(Hash) || (operation.keys - %w[authentication name]).any? ||
      !%w[authentication name].all? { |key| operation.key?(key) } ||
      !AUTHENTICATION_REQUIREMENTS.include?(operation["authentication"]) || !OPERATIONS.include?(operation["name"])
  end

  names = operations.map { |operation| operation["name"] }
  names.uniq.length == names.length && %w[list-offerings get-offering].all? { |name| names.include?(name) }
end

def depth(value)
  children = value.is_a?(Hash) ? value.values : value.is_a?(Array) ? value : []
  children.empty? ? 1 : 1 + children.map { |child| depth(child) }.max
end

def valid_document?(document, source)
  return false unless source.bytesize <= 65_536 && document.is_a?(Hash) && depth(document) <= 8

  required = %w[odp_version name description language localizations operations http]
  return false unless required.all? { |key| document.key?(key) }
  return false if document.key?("id") || document.key?("web_url")
  return false unless document["odp_version"] == "1.0"
  return false unless document["name"].is_a?(String) && document["name"].length.between?(1, 128)
  return false unless document["description"].is_a?(String) && document["description"].length.between?(1, 1024)

  language = document["language"]
  localizations = document["localizations"]
  return false unless language.is_a?(String) && language.match?(LANGUAGE_TAG)
  return false unless localizations.is_a?(Array) && localizations.length.between?(1, 16)
  return false unless localizations.all? { |tag| tag.is_a?(String) && tag.match?(LANGUAGE_TAG) }
  folded = localizations.map(&:downcase)
  return false unless folded.uniq.length == folded.length && folded.include?(language.downcase)

  keywords = document["keywords"]
  if keywords
    return false unless keywords.is_a?(Array) && keywords.length <= 32
    return false unless keywords.all? do |keyword|
      keyword.is_a?(String) && keyword.length.between?(1, 64) && keyword.match?(/\A\S(?:.*\S)?\z/m)
    end
    return false unless keywords.uniq.length == keywords.length && keywords.sum(&:length) <= 1024
  end

  operations = document["operations"]
  return false unless operations_valid?(operations)
  operation_names = operations.map { |operation| operation["name"] }
  requires_authentication = operations.any? { |operation| operation["authentication"] != "not-required" }
  return false if requires_authentication && document.dig("protocols", "enrollment").nil?
  return false if document.key?("search_capabilities") &&
    !search_capabilities_valid?(document["search_capabilities"], operation_names)
  return false if document.key?("protocols") && !protocols_valid?(document["protocols"])

  endpoint_base = document.dig("http", "endpoint_base")
  endpoint_base.is_a?(String) && endpoint_base.ascii_only? && endpoint_base.length <= 2048 && endpoint_base.match?(ENDPOINT_BASE)
end

root = Pathname.new(__dir__).join("..", "test-vectors", "service-document").expand_path
errors = []

Dir[root.join("*.json")].sort.each do |path|
  vector = JSON.parse(Pathname.new(path).read)
  vector.fetch("cases").each do |test_case|
    source = JSON.generate(test_case.fetch("document"))
    actual = valid_document?(test_case.fetch("document"), source)
    errors << "#{path}: #{test_case.fetch('name')} validity mismatch" unless actual == test_case.fetch("valid")
  end
end

examples = Pathname.new(__dir__).join("..", "examples").expand_path
Dir[examples.join("**", "*-service.json")].sort.each do |name|
  example = Pathname.new(name)
  example_source = example.read
  errors << "#{example}: invalid Service Document example" unless valid_document?(JSON.parse(example_source), example_source)
end

if errors.empty?
  puts "Service Document vectors OK"
else
  warn errors.join("\n")
  exit 1
end
