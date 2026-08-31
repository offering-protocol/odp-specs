#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"

PROBLEM_TYPE = %r{\Ahttps://offeringprotocol\.org/problems/[a-z0-9][a-z0-9-]*\z}
PROBLEM_CODE = /\A[A-Z][A-Z0-9_]{0,63}\z/
CORE_STATUSES = {
  "INVALID_REQUEST" => 400,
  "NOT_AUTHENTICATED" => 401,
  "NOT_AUTHORIZED" => 403,
  "NOT_FOUND" => 404,
  "NOT_ACCEPTABLE" => 406,
  "CONTINUATION_EXPIRED" => 410,
  "REQUEST_TOO_LARGE" => 413,
  "UNSUPPORTED_MEDIA_TYPE" => 415,
  "RATE_LIMITED" => 429,
  "SERVICE_UNAVAILABLE" => 503
}.freeze
LIMITS = {
  "request" => 65_536,
  "offering" => 524_288,
  "page" => 524_288,
  "problem" => 16_384,
  "schema" => 262_144,
  "schema_graph" => 1_048_576
}.freeze

def invalid_param_valid?(parameter)
  return false unless parameter.is_a?(Hash) && %w[in name reason].all? { |field| parameter[field].is_a?(String) }
  return false unless %w[query body header path].include?(parameter["in"]) && !parameter["reason"].empty?

  parameter["in"] == "body" ? parameter["name"].empty? || parameter["name"].start_with?("/") :
    !parameter["name"].empty?
end

def problem_valid?(problem, http_status)
  return false unless problem.is_a?(Hash) && %w[type title status code].all? { |field| problem.key?(field) }
  return false unless problem["type"].is_a?(String) && problem["type"].match?(PROBLEM_TYPE)
  return false unless problem["title"].is_a?(String) && !problem["title"].empty?
  return false unless problem["status"] == http_status && http_status.between?(400, 599)
  return false unless problem["code"].is_a?(String) && problem["code"].match?(PROBLEM_CODE)
  expected_type = "https://offeringprotocol.org/problems/#{problem["code"].downcase.tr('_', '-')}"
  return false unless problem["type"] == expected_type
  return false if CORE_STATUSES.key?(problem["code"]) && CORE_STATUSES.fetch(problem["code"]) != http_status
  return false if problem.key?("invalid_params") &&
    (problem["code"] != "INVALID_REQUEST" || !problem["invalid_params"].is_a?(Array) ||
      problem["invalid_params"].empty? ||
      !problem["invalid_params"].all? { |parameter| invalid_param_valid?(parameter) })

  true
end

def evaluate(test_case)
  case test_case.fetch("operation")
  when "validate-problem"
    problem_valid?(test_case.fetch("problem"), test_case.fetch("http_status"))
  when "validate-limit"
    test_case.fetch("bytes") <= LIMITS.fetch(test_case.fetch("resource"))
  when "limit-failure-scope"
    {
      "preserved_items" => test_case.fetch("prior_items"),
      "continue" => test_case.fetch("current_page_valid")
    }
  when "retry"
    transient = [429, 503].include?(test_case.fetch("status"))
    wait = test_case.fetch("retry_after_seconds")
    transient && test_case.fetch("attempt") <= 3 && test_case.fetch("elapsed_seconds") + wait <= 30
  end
end

path = Pathname.new(__dir__).join("..", "test-vectors", "errors-limits", "contract.json").expand_path
vector = JSON.parse(path.read)
errors = vector.fetch("cases").filter_map do |test_case|
  expected = test_case.key?("valid") ? test_case.fetch("valid") :
    test_case.fetch("retry", test_case["expected"])
  actual = evaluate(test_case)
  "#{path}: #{test_case.fetch('name')} mismatch" unless actual == expected
end

if errors.empty?
  puts "Error and limit vectors OK"
else
  warn errors.join("\n")
  exit 1
end
