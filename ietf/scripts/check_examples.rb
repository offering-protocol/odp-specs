#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"
require "uri"
require_relative "odp_identity"
require_relative "odp_versioning"

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

def validate_references(value, relative, errors, path = "$")
  case value
  when Hash
    value.each do |key, child|
      if %w[href web_url next].include?(key) && !OdpIdentity.resource_reference?(child)
        errors << "#{relative}: #{path}.#{key} must be a valid resource reference"
      end
      validate_references(child, relative, errors, "#{path}.#{key}")
    end
  when Array
    value.each_with_index { |child, index| validate_references(child, relative, errors, "#{path}[#{index}]") }
  end
end

def absolute_https?(value)
  uri = URI.parse(value.to_s)
  uri.is_a?(URI::HTTPS) && !uri.host.to_s.empty?
rescue URI::InvalidURIError
  false
end

Dir[root.join("**/*.json")].sort.each do |name|
  path = Pathname.new(name)
  document = load_json(path, errors)
  unless path.basename.to_s.end_with?(".schema.json")
    version = document.is_a?(Hash) && document["odp_version"]
    errors << "#{path.relative_path_from(root)}: odp_version must be 1.0" unless version == "1.0" && OdpVersioning.parse(version)
  end
  validate_references(document, path.relative_path_from(root), errors) if document
end

Dir[root.join("**/*-offering.json")].sort.each do |name|
  path = Pathname.new(name)
  relative = path.relative_path_from(root)
  document = load_json(path, errors)
  next unless document.is_a?(Hash)

  require_fields(document, %w[odp_version id name description collection_ids schema attributes actions], relative, errors)
  errors << "#{relative}: id must be a valid local resource identifier" unless OdpIdentity.local_identifier?(document["id"])
  schema_url = document.dig("schema", "url")
  errors << "#{relative}: schema.url must be an absolute HTTPS URL" unless absolute_https?(schema_url)
  errors << "#{relative}: attributes must be an object" unless document["attributes"].is_a?(Hash)
  errors << "#{relative}: actions must be an array" unless document["actions"].is_a?(Array)
  errors << "#{relative}: collection_ids must contain unique local identifiers" unless
    document["collection_ids"].is_a?(Array) && document["collection_ids"].uniq.length == document["collection_ids"].length &&
    document["collection_ids"].all? { |identifier| OdpIdentity.local_identifier?(identifier) }
end

Dir[root.join("**/*-collection.json")].sort.each do |name|
  path = Pathname.new(name)
  relative = path.relative_path_from(root)
  document = load_json(path, errors)
  next unless document.is_a?(Hash)

  require_fields(document, %w[odp_version id name description language localizations parent_ids filter_capabilities], relative, errors)
  errors << "#{relative}: id must be a valid local resource identifier" unless OdpIdentity.local_identifier?(document["id"])
  errors << "#{relative}: parent_ids must contain unique local identifiers" unless
    document["parent_ids"].is_a?(Array) && document["parent_ids"].uniq.length == document["parent_ids"].length &&
    document["parent_ids"].all? { |identifier| OdpIdentity.local_identifier?(identifier) }
  errors << "#{relative}: localizations must contain language" unless
    document["localizations"].is_a?(Array) && document["localizations"].include?(document["language"])
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

Dir[root.join("*")].select { |path| Pathname.new(path).directory? }.sort.each do |directory|
  directory_path = Pathname.new(directory)
  collection_ids = Dir[directory_path.join("**/*-collection.json")].filter_map do |name|
    document = load_json(Pathname.new(name), errors)
    document["id"] if document.is_a?(Hash)
  end
  Dir[directory_path.join("**/*-offering.json")].sort.each do |name|
    document = load_json(Pathname.new(name), errors)
    next unless document.is_a?(Hash)

    missing = Array(document["collection_ids"]) - collection_ids
    errors << "#{Pathname.new(name).relative_path_from(root)}: unknown collection_ids #{missing.join(', ')}" unless missing.empty?
  end
end

if errors.empty?
  puts "Examples OK"
else
  warn errors.join("\n")
  exit 1
end
