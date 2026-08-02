#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "open3"
require "pathname"
require "rbconfig"
require "tempfile"

root = Pathname.new(__dir__).join("..").expand_path
runner = Pathname.new(__dir__).join("run_conformance.rb").expand_path
adapter = root.join("conformance", "fixture-adapter.rb")
errors = []

def run_harness(runner, adapter, output, status)
  Open3.capture3(
    RbConfig.ruby,
    runner.to_s,
    "--role", "agent",
    "--implementation-name", "Harness fixture",
    "--implementation-version", "1.0.0",
    "--suite", "conformance",
    "--output", output.path,
    "--",
    RbConfig.ruby,
    adapter.to_s,
    status
  )
end

Tempfile.create(["odp-conformance-report", ".json"]) do |output|
  _, stderr, status = run_harness(runner, adapter, output, "passed")
  errors << "passing adapter failed: #{stderr}" unless status.success?

  report = JSON.parse(output.read)
  errors << "report role mismatch" unless report["role"] == "agent"
  errors << "report version mismatch" unless report["odp_version"] == "1.0"
  errors << "vector revision is not content-addressed" unless report["vector_revision"].match?(/\Asha256:[0-9a-f]{64}\z/)
  errors << "suite aggregation mismatch" unless report["suites"] == [{
    "category" => "conformance",
    "passed" => 2,
    "failed" => 0,
    "skipped" => 0
  }]
end

Tempfile.create(["odp-conformance-report", ".json"]) do |output|
  _, _, status = run_harness(runner, adapter, output, "failed")
  errors << "failing adapter did not fail the run" unless status.exitstatus == 1
end

Tempfile.create(["odp-conformance-report", ".json"]) do |output|
  _, stderr, status = run_harness(runner, adapter, output, "invalid")
  errors << "invalid adapter response did not fail the harness" unless status.exitstatus == 1
  errors << "invalid adapter response error is unclear" unless stderr.include?("adapter response status is invalid")
end

if errors.empty?
  puts "Conformance harness OK"
else
  warn errors.join("\n")
  exit 1
end
