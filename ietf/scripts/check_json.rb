#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"

root = Pathname.new(__dir__).join("..").expand_path
ignored_directories = %w[.bundle .cache .refcache .venv vendor].freeze
paths = Dir[root.join("**/*.json")].sort.reject do |path|
  (Pathname.new(path).relative_path_from(root).each_filename.to_a & ignored_directories).any?
end
abort "No JSON files found" if paths.empty?

def canonical_json(value, depth = 0)
  indent = "  " * depth
  child_indent = "  " * (depth + 1)

  case value
  when Hash
    return "{}" if value.empty?

    members = value.map do |key, child|
      "#{child_indent}#{JSON.generate(key)}: #{canonical_json(child, depth + 1)}"
    end
    "{\n#{members.join(",\n")}\n#{indent}}"
  when Array
    return "[]" if value.empty?

    members = value.map { |child| "#{child_indent}#{canonical_json(child, depth + 1)}" }
    "[\n#{members.join(",\n")}\n#{indent}]"
  else
    JSON.generate(value)
  end
end

errors = []
paths.each do |path|
  file = Pathname.new(path)
  begin
    parsed = JSON.parse(file.read)
    formatted = "#{canonical_json(parsed)}\n"
    errors << "#{file.relative_path_from(root)}: JSON is not canonically formatted" unless file.read == formatted
  rescue JSON::ParserError => e
    errors << "#{file.relative_path_from(root)}: invalid JSON: #{e.message}"
  end
end

if errors.empty?
  puts "JSON OK (#{paths.length} files)"
else
  warn errors.join("\n")
  exit 1
end
