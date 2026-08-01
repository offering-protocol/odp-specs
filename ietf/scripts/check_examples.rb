#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"
require "uri"

root = Pathname.new(__dir__).join("..", "examples").expand_path
errors = []

def load_json(path, errors)
  JSON.parse(path.read)
rescue JSON::ParserError => e
  errors << "#{path}: invalid JSON: #{e.message}"
  nil
end

def require_fields(document, fields, relative, errors)
  fields.each { |field| errors << "#{relative}: missing #{field}" unless document.key?(field) }
end

def absolute_https?(value)
  uri = URI.parse(value.to_s)
  uri.is_a?(URI::HTTPS) && !uri.host.to_s.empty?
rescue URI::InvalidURIError
  false
end

Dir[root.join("**/*-offering.json")].sort.each do |name|
  path = Pathname.new(name)
  relative = path.relative_path_from(root)
  document = load_json(path, errors)
  next unless document.is_a?(Hash)

  require_fields(document, %w[odp_version id name description href schema attributes actions], relative, errors)
  %w[id href].each do |field|
    errors << "#{relative}: #{field} must be an absolute HTTPS URL" unless absolute_https?(document[field])
  end
  if document.key?("web_url") && !absolute_https?(document["web_url"])
    errors << "#{relative}: web_url must be an absolute HTTPS URL"
  end
  schema_url = document.dig("schema", "url")
  errors << "#{relative}: schema.url must be an absolute HTTPS URL" unless absolute_https?(schema_url)
  errors << "#{relative}: attributes must be an object" unless document["attributes"].is_a?(Hash)
  errors << "#{relative}: actions must be an array" unless document["actions"].is_a?(Array)
end

Dir[root.join("**/*-collection.json")].sort.each do |name|
  path = Pathname.new(name)
  relative = path.relative_path_from(root)
  document = load_json(path, errors)
  next unless document.is_a?(Hash)

  require_fields(document, %w[odp_version id name description href offerings filter_capabilities], relative, errors)
  sources = %w[inline linked].select { |field| document.fetch("filter_capabilities", {}).key?(field) }
  errors << "#{relative}: filter_capabilities must contain exactly one of inline or linked" unless sources.length == 1
end

Dir[root.join("**/*-filters-page-*.json")].sort.each do |name|
  path = Pathname.new(name)
  relative = path.relative_path_from(root)
  document = load_json(path, errors)
  next unless document.is_a?(Hash)

  require_fields(document, %w[items], relative, errors)
  Array(document["items"]).each do |filter|
    require_fields(filter, %w[id title description type operators sortable], relative, errors) if filter.is_a?(Hash)
  end
end

if errors.empty?
  puts "Examples OK"
else
  warn errors.join("\n")
  exit 1
end
