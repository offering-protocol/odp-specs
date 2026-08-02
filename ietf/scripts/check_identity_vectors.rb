#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"
require_relative "odp_identity"

root = Pathname.new(__dir__).join("..", "test-vectors", "identity").expand_path
errors = []
required_metadata = %w[id title description drafts category applies_to subject cases]

Dir[root.join("*.json")].sort.each do |path|
  vector = JSON.parse(Pathname.new(path).read)
  missing = required_metadata.reject { |field| vector.key?(field) }
  errors << "#{path}: missing metadata: #{missing.join(', ')}" unless missing.empty?
  next if vector["subject"] == "identity-comparison"

  predicate = case vector.fetch("subject")
              when "service-origin" then OdpIdentity.method(:canonical_origin?)
              when "local-identifier" then OdpIdentity.method(:local_identifier?)
              when "resource-reference" then OdpIdentity.method(:resource_reference?)
              else abort "#{path}: unknown subject"
              end

  vector.fetch("cases").each do |test_case|
    actual = predicate.call(test_case["value"])
    expected = test_case.fetch("valid")
    errors << "#{path}: #{test_case.fetch('name')} expected #{expected}, got #{actual}" unless actual == expected
  end
end

unpaired_surrogate = "\xED\xA0\x80".b.force_encoding(Encoding::UTF_8)
errors << "unpaired surrogate must be rejected" if OdpIdentity.local_identifier?(unpaired_surrogate)

comparison_path = root.join("identity-comparison.json")
comparison = JSON.parse(comparison_path.read)
comparison.fetch("cases").each do |test_case|
  left = test_case.fetch("left")
  right = test_case.fetch("right")
  actual = left.fetch("service") == right.fetch("service") &&
           left.fetch("type") == right.fetch("type") &&
           left.fetch("id") == right.fetch("id")
  expected = test_case.fetch("same_identity")
  errors << "#{comparison_path}: #{test_case.fetch('name')} expected #{expected}, got #{actual}" unless actual == expected
end

if errors.empty?
  puts "Identity vectors OK"
else
  warn errors.join("\n")
  exit 1
end
