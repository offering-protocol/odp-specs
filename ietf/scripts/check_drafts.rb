#!/usr/bin/env ruby
# frozen_string_literal: true

require "yaml"
require "date"

required_metadata = %w[title abbrev docname category ipr submissiontype author]
required_sections = [
  "# Introduction",
  "# Requirements Language",
  "# Scope",
  "# Non-Goals",
  "# Terminology",
  "# Roles",
  "# Resource Identity and References",
  "# Discovery Architecture",
  "# Extensibility Model",
  "# Composition Boundaries",
  "# Conformance",
  "# IANA Considerations",
  "# Security Considerations",
  "# Privacy Considerations"
].freeze

drafts = Dir.glob(File.join(__dir__, "..", "specs", "**", "draft-*.md")).sort
abort "No Internet-Drafts found" if drafts.empty?

drafts.each do |path|
  source = File.read(path)
  match = source.match(/\A---\n(.*?)\n\.\.\.\n/m)
  abort "#{path}: missing kramdown-rfc YAML header" unless match

  metadata = YAML.safe_load(match[1], permitted_classes: [Date], aliases: false)
  abort "#{path}: YAML header must be a mapping" unless metadata.is_a?(Hash)

  missing_metadata = required_metadata.reject { |key| metadata.key?(key) && !metadata[key].nil? }
  abort "#{path}: missing metadata: #{missing_metadata.join(', ')}" unless missing_metadata.empty?

  expected_docname = File.basename(path, ".md")
  abort "#{path}: docname must equal #{expected_docname}" unless metadata["docname"] == expected_docname

  authors = metadata["author"]
  abort "#{path}: author must contain at least one entry" unless authors.is_a?(Array) && !authors.empty?

  missing_sections = required_sections.reject { |section| source.include?("\n#{section}\n") }
  abort "#{path}: missing sections: #{missing_sections.join(', ')}" unless missing_sections.empty?

  abort "#{path}: contains an unresolved placeholder" if source.match?(/\b(?:TODO|TBD)\b|\[(?:insert|add)\b/i)
  abort "#{path}: references must be declared in YAML" if source.match?(/^# References$/)
  abort "#{path}: HTTP semantics must reference RFC 9110" unless source.include?("RFC9110")
end

puts "Drafts OK"
