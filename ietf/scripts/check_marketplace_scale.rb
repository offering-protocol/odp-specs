#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "json"
require "optparse"
require "pathname"

root = Pathname.new(__dir__).join("..").expand_path
profile_path = root.join("fixtures", "marketplace-scale", "profile.json")
profile = JSON.parse(profile_path.read)
output = nil
OptionParser.new { |parser| parser.on("--output DIRECTORY") { |value| output = Pathname.new(value).expand_path } }.parse!

PAGE_LIMIT = 100
PAGE_BYTES = 524_288
SERVICE_DOCUMENT_BYTES = 65_536
CAPABILITY_PAGE_LIMIT = 16

def page(total, offset, limit)
  raise ArgumentError unless total.positive? && offset.between?(0, total - 1) && limit.between?(1, PAGE_LIMIT)

  length = [limit, total - offset].min
  [Array.new(length) { |index| yield(offset + index) }, length]
end

def envelope(items, next_reference = nil)
  document = { "odp_version" => "1.0", "items" => items }
  document["next"] = next_reference if next_reference
  document
end

def offering(index)
  {
    "id" => format("offering-%08d", index),
    "name" => "Marketplace Offering #{index}",
    "price" => { "type" => "fixed", "amount" => format("%d.99", index % 10_000), "currency" => "USD" },
    "detail_fields" => ["/description", "/attributes", "/actions"]
  }
end

def collection(index)
  {
    "id" => format("collection-%06d", index),
    "name" => "Marketplace Collection #{index}",
    "detail_fields" => ["/description", "/search_capabilities"]
  }
end

def filter_definition(index)
  {
    "id" => format("filter-%04d", index),
    "title" => "Filter #{index}",
    "description" => "Generated marketplace filter #{index}.",
    "type" => "string",
    "operators" => ["eq", "in"],
    "refinable" => true
  }
end

def sort_definition(index)
  {
    "id" => format("sort-%03d", index),
    "title" => "Sort #{index}",
    "description" => "Generated indexed marketplace sort #{index}.",
    "keys" => [
      { "filter_id" => format("filter-%04d", index), "direction" => "ascending", "missing" => "last" }
    ]
  }
end

def capability_pages(total, prefix)
  pages = []
  offset = 0
  while offset < total
    items, generated = page(total, offset, PAGE_LIMIT) { |index| yield(index) }
    next_offset = offset + generated
    next_reference = next_offset < total ? "/odp/#{prefix}?cursor=#{next_offset}" : nil
    pages << envelope(items, next_reference)
    offset = next_offset
  end
  pages
end

def assert(condition, message, errors)
  errors << message unless condition
end

def write_document(directory, name, document)
  File.write(directory.join(name), "#{JSON.pretty_generate(document)}\n")
end

started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
errors = []
generated = {}
catalog = profile.fetch("catalog")
page_profile = profile.fetch("pages")
assert(page_profile.fetch("items") == PAGE_LIMIT, "fixture page item limit drifted from ODP", errors)
assert(page_profile.fetch("maximum_decoded_bytes") == PAGE_BYTES, "fixture page byte limit drifted from ODP", errors)
assert(profile.dig("capabilities", "maximum_pages_per_source") == CAPABILITY_PAGE_LIMIT,
       "fixture capability page limit drifted from ODP", errors)

service_document = JSON.parse(root.join("examples", "marketplace", "marketplace-service.json").read)
assert(JSON.generate(service_document).bytesize <= SERVICE_DOCUMENT_BYTES, "Service Document exceeds 65,536 bytes", errors)
generated["service-document.json"] = service_document

{
  "offerings" => [catalog.fetch("offerings"), method(:offering)],
  "collections" => [catalog.fetch("collections"), method(:collection)]
}.each do |kind, (total, factory)|
  profile.fetch("sample_offsets").fetch(kind).each_with_index do |offset, sample_index|
    items, work = page(total, offset, page_profile.fetch("items")) { |index| factory.call(index) }
    next_offset = offset + work
    document = envelope(items, next_offset < total ? "/odp/#{kind}?cursor=#{next_offset}" : nil)
    assert(work <= PAGE_LIMIT, "#{kind} sample materialized more than one page", errors)
    assert(JSON.generate(document).bytesize <= PAGE_BYTES, "#{kind} sample exceeds page byte limit", errors)
    generated["#{kind}-sample-#{sample_index + 1}.json"] = document
  end
end

filter_pages = capability_pages(profile.dig("capabilities", "filters"), "filters") { |index| filter_definition(index) }
sort_pages = capability_pages(profile.dig("capabilities", "sorts"), "sorts") { |index| sort_definition(index) }
{ "filters" => filter_pages, "sorts" => sort_pages }.each do |kind, pages|
  expected = profile.dig("capabilities", kind)
  assert(pages.length <= CAPABILITY_PAGE_LIMIT, "#{kind} exceeds capability page limit", errors)
  assert(pages.sum { |document| document.fetch("items").length } == expected,
         "#{kind} fixture did not generate the complete capability source", errors)
  assert(pages.all? { |document| document.fetch("items").length <= PAGE_LIMIT }, "#{kind} page exceeds item limit", errors)
  assert(pages.all? { |document| JSON.generate(document).bytesize <= PAGE_BYTES }, "#{kind} page exceeds byte limit", errors)
  pages.each_with_index { |document, index| generated["#{kind}-page-#{index + 1}.json"] = document }
end

refinement_profile = profile.fetch("refinements")
refinements = Array.new(refinement_profile.fetch("groups")) do |group|
  {
    "filter_id" => format("filter-%04d", group),
    "values" => Array.new(refinement_profile.fetch("values_per_group")) do |value|
      { "value" => "value-#{value}", "count" => catalog.fetch("offerings") - value }
    end
  }
end
refinement_response = envelope(Array.new(page_profile.fetch("items")) { |index| offering(index) })
refinement_response["refinements"] = refinements
assert(JSON.generate(refinement_response).bytesize <= PAGE_BYTES, "maximum refinement response exceeds page byte limit", errors)
generated["offering-search-with-refinements.json"] = refinement_response

if output
  FileUtils.mkdir_p(output)
  FileUtils.cp(profile_path, output.join("profile.json"))
  generated.each { |name, document| write_document(output, name, document) }
end

elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
if errors.empty?
  puts format("Marketplace scale fixture OK (%d documents, %.3fs diagnostic)", generated.length, elapsed)
else
  warn errors.join("\n")
  exit 1
end
