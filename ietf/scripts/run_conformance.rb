#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "open3"
require "optparse"
require "pathname"
require_relative "conformance_harness"

options = { suites: [] }
parser = OptionParser.new do |arguments|
  arguments.banner = "Usage: run_conformance.rb [options] -- ADAPTER [ARGUMENT ...]"
  arguments.on("--role ROLE", ConformanceHarness::ROLES) { |role| options[:role] = role }
  arguments.on("--implementation-name NAME") { |name| options[:name] = name }
  arguments.on("--implementation-version VERSION") { |version| options[:version] = version }
  arguments.on("--suite CATEGORY") { |suite| options[:suites] << suite }
  arguments.on("--output PATH") { |path| options[:output] = path }
end
parser.order!
ARGV.shift if ARGV.first == "--"

required = %i[role name version output]
missing = required.reject { |key| options[key].is_a?(String) && !options[key].empty? }
abort parser.to_s unless missing.empty? && !ARGV.empty?

root = Pathname.new(__dir__).join("..", "test-vectors").expand_path
index, vectors = ConformanceHarness.load_vectors(root, options.fetch(:suites))
requests = ConformanceHarness.requests(vectors, options.fetch(:role))
abort "no cases selected" if requests.empty?

expected_sequences = requests.map { |request| request.fetch("sequence") }
responses = {}
adapter_errors = []
status = nil

Open3.popen3(*ARGV) do |stdin, stdout, stderr, wait_thread|
  error_reader = Thread.new { stderr.read }
  writer = Thread.new do
    requests.each { |request| stdin.puts(JSON.generate(request)) }
    stdin.close
  rescue Errno::EPIPE => error
    adapter_errors << error.message
  end

  stdout.each_line do |line|
    response = JSON.parse(line)
    ConformanceHarness.validate_response!(response, expected_sequences)
    sequence = response.fetch("sequence")
    raise "adapter returned sequence #{sequence} more than once" if responses.key?(sequence)

    responses[sequence] = response
  end
  writer.join
  status = wait_thread.value
  adapter_stderr = error_reader.value
  warn adapter_stderr unless adapter_stderr.empty?
rescue JSON::ParserError => error
  abort "adapter returned invalid JSON: #{error.message}"
rescue RuntimeError => error
  abort error.message
end

abort adapter_errors.join("\n") unless adapter_errors.empty?
abort "adapter exited with status #{status.exitstatus}" unless status.success?

missing_sequences = expected_sequences - responses.keys
abort "adapter omitted sequences: #{missing_sequences.join(', ')}" unless missing_sequences.empty?

report = ConformanceHarness.report(
  name: options.fetch(:name),
  version: options.fetch(:version),
  role: options.fetch(:role),
  vector_revision: ConformanceHarness.revision(index, vectors),
  requests: requests,
  responses: responses
)
Pathname.new(options.fetch(:output)).write("#{JSON.pretty_generate(report)}\n")

requests.each do |request|
  response = responses.fetch(request.fetch("sequence"))
  next unless response.fetch("status") == "failed"

  identity = "#{request.dig('vector', 'id')}/#{request.dig('case', 'name')}"
  warn "#{identity}: #{response.fetch('message', 'failed')}"
end

failed = report.fetch("suites").sum { |suite| suite.fetch("failed") }
exit(failed.zero? ? 0 : 1)
