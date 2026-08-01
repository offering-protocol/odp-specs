#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"

root = Pathname.new(__dir__).join("..").expand_path
paths = Dir[root.join("**/*.json")].sort
abort "No JSON files found" if paths.empty?

errors = []
paths.each do |path|
  file = Pathname.new(path)
  begin
    parsed = JSON.parse(file.read)
    formatted = "#{JSON.pretty_generate(parsed)}\n"
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
