#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"
require_relative "odp_identity"

OPERATIONS = %w[
  list-collections search-collections get-collection list-collection-offerings
  list-offerings search-offerings get-offering
].freeze
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

def search_capabilities_valid?(capabilities, supported)
  return false unless capabilities.is_a?(Hash) && (capabilities.key?("filters") || capabilities.key?("sorts"))
  return false unless supported.include?("search-offerings")
  return false if capabilities.key?("filters") && !capability_source_valid?(capabilities["filters"], 32)
  return false if capabilities.key?("sorts") && !capability_source_valid?(capabilities["sorts"], 16)

  true
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
    return false unless keywords.all? { |keyword| keyword.is_a?(String) && keyword.length.between?(1, 64) }
    return false unless keywords.uniq.length == keywords.length && keywords.sum(&:length) <= 1024
  end

  supported = document.dig("operations", "supported")
  return false unless supported.is_a?(Array) && supported.length.between?(1, 32)
  return false unless supported.uniq.length == supported.length && supported.all? { |operation| OPERATIONS.include?(operation) }
  return false if document.key?("search_capabilities") &&
    !search_capabilities_valid?(document["search_capabilities"], supported)

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

example = Pathname.new(__dir__).join("..", "examples", "marketplace", "marketplace-service.json")
example_source = example.read
errors << "#{example}: invalid Service Document example" unless valid_document?(JSON.parse(example_source), example_source)

if errors.empty?
  puts "Service Document vectors OK"
else
  warn errors.join("\n")
  exit 1
end
