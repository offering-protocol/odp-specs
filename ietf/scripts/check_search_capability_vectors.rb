#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"
require "uri"
require_relative "odp_identity"

IDENTIFIER = /\A[A-Za-z0-9._~-]{1,64}\z/
INLINE_LIMITS = { "filters" => 32, "sorts" => 16 }.freeze
EFFECTIVE_LIMITS = { "filters" => 1_024, "sorts" => 128 }.freeze
LINKED_PAGE_LIMIT = 16

def same_origin?(service_origin, reference)
  return false unless OdpIdentity.canonical_origin?(service_origin) && OdpIdentity.resource_reference?(reference)

  origin = URI.parse(service_origin)
  resolved = URI.join("#{service_origin}/", reference)
  resolved.scheme == origin.scheme && resolved.host == origin.host && resolved.port == origin.port
rescue URI::InvalidURIError
  false
end

def source_valid?(kind, source, service_origin)
  return false unless source.is_a?(Hash)

  forms = %w[inline linked].select { |field| source.key?(field) }
  return false unless forms.length == 1

  if source.key?("inline")
    definitions = source["inline"]
    return false unless definitions.is_a?(Array) && definitions.length.between?(1, INLINE_LIMITS.fetch(kind))

    identifiers = definitions.map { |definition| definition["id"] }
    identifiers.all? { |identifier| identifier.is_a?(String) && identifier.match?(IDENTIFIER) } &&
      identifiers.uniq.length == identifiers.length
  else
    link = source["linked"]
    link.is_a?(Hash) && same_origin?(service_origin, link["href"])
  end
end

def advertisement_valid?(advertisement, service_origin, operations)
  return false unless advertisement.is_a?(Hash) && (advertisement.key?("filters") || advertisement.key?("sorts"))
  return false unless operations.include?("search-offerings")

  %w[filters sorts].all? do |kind|
    !advertisement.key?(kind) || source_valid?(kind, advertisement[kind], service_origin)
  end
end

def linked_source_valid?(test_case)
  pages = test_case.fetch("pages")
  return false unless test_case.fetch("method") == "GET" && same_origin?(test_case.fetch("service_origin"), test_case.fetch("href"))
  return false unless pages.is_a?(Array) && pages.length.between?(1, LINKED_PAGE_LIMIT)
  return false unless pages.all? { |page| page["odp_version"] == "1.0" && page["items"].is_a?(Array) && page["items"].length <= 100 }

  identifiers = pages.flat_map { |page| page["items"].map { |definition| definition["id"] } }
  identifiers.all? { |identifier| identifier.is_a?(String) && identifier.match?(IDENTIFIER) } &&
    identifiers.uniq.length == identifiers.length
end

def merge_capabilities(test_case)
  effective = { "filters" => [], "sorts" => [], "issues" => [] }
  scopes = [test_case.fetch("service")]
  scopes << test_case.fetch("selected_collection") if test_case["collection_id"]

  %w[filters sorts].each do |kind|
    definitions = []
    scopes.each do |scope|
      source = scope.fetch(kind, [])
      if definitions.length + source.length > EFFECTIVE_LIMITS.fetch(kind)
        effective["issues"] << "#{kind}-limit"
      else
        definitions.concat(source)
      end
    end

    grouped = definitions.group_by { |definition| definition.fetch("id") }
    conflicts = grouped.select { |_identifier, values| values.length > 1 }.keys
    effective["issues"].concat(conflicts.map { |identifier| "#{kind}-conflict:#{identifier}" })
    effective[kind] = grouped.filter_map { |_identifier, values| values.first if values.length == 1 }
  end

  filter_ids = effective["filters"].map { |definition| definition.fetch("id") }
  effective["sorts"] = effective["sorts"].filter_map do |sort|
    references = sort.fetch("keys").map { |key| key.fetch("filter_id") }
    if (references - filter_ids).empty?
      sort
    else
      effective["issues"] << "sort-reference:#{sort.fetch('id')}"
      nil
    end
  end

  {
    "filter_ids" => effective["filters"].map { |definition| definition.fetch("id") },
    "sort_ids" => effective["sorts"].map { |definition| definition.fetch("id") },
    "issues" => effective["issues"].sort
  }
end

path = Pathname.new(__dir__).join("..", "test-vectors", "search-capabilities", "contract.json").expand_path
vector = JSON.parse(path.read)
errors = vector.fetch("cases").filter_map do |test_case|
  actual = case test_case.fetch("operation")
           when "validate-advertisement"
             advertisement_valid?(test_case.fetch("advertisement"), test_case.fetch("service_origin"), test_case.fetch("operations"))
           when "validate-linked-source"
             linked_source_valid?(test_case)
           when "validate-linked-page-count"
             test_case.fetch("page_count").between?(1, LINKED_PAGE_LIMIT)
           when "merge-capabilities"
             merge_capabilities(test_case)
           else
             :unknown
           end
  expected = test_case.key?("valid") ? test_case.fetch("valid") : test_case.fetch("expected")
  if actual == :unknown
    "#{path}: unknown operation #{test_case['operation']}"
  elsif actual != expected
    "#{path}: #{test_case.fetch('name')} mismatch"
  end
end

if errors.empty?
  puts "Search capability vectors OK"
else
  warn errors.join("\n")
  exit 1
end
