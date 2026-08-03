#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"

def advertisement_valid?(protocols)
  return false unless protocols.is_a?(Hash) && !protocols.empty?
  return false unless (protocols.keys - %w[enrollment payments]).empty?
  return false if protocols.key?("enrollment") && protocols["enrollment"] != [{ "name" => "aep" }]

  payments = protocols["payments"]
  return false if payments &&
    (!payments.is_a?(Array) || payments.empty? || payments.length > 2 ||
      payments.any? do |payment|
        !payment.is_a?(Hash) || payment.keys.sort != %w[authentication name] ||
          !%w[not-required required].include?(payment["authentication"]) || !%w[mpp x402].include?(payment["name"])
      end || payments.map { |payment| payment["name"] }.uniq.length != payments.length)

  return false if payments&.any? { |payment| payment["authentication"] == "required" } && !protocols.key?("enrollment")

  protocols.key?("enrollment") || protocols.key?("payments")
end

def live_protocols(response)
  status = response.fetch("status")
  headers = response.fetch("headers", {}).transform_keys(&:downcase)
  protocols = []
  protocols << "aep" if status == 401 && headers.fetch("www-authenticate", "").match?(/(?:^|,)\s*AEP(?:\s|$)/i)
  if status == 402
    protocols << "mpp" if headers.fetch("www-authenticate", "").match?(/(?:^|,)\s*Payment(?:\s|$)/i)
    payment_required = headers["payment-required"]
    protocols << "x402" if payment_required.is_a?(String) && !payment_required.empty?
  end
  protocols
end

def sequence_valid?(requires, responses)
  expected = []
  expected << 401 if requires.include?("aep")
  expected << 402 if (requires & %w[mpp x402]).any?
  expected << 200
  responses == expected
end

path = Pathname.new(__dir__).join("..", "test-vectors", "composition", "contract.json").expand_path
vector = JSON.parse(path.read)
errors = vector.fetch("cases").filter_map do |test_case|
  actual = case test_case.fetch("operation")
           when "validate-advertisement"
             advertisement_valid?(test_case.fetch("protocols"))
           when "classify-live-response"
             live_protocols(test_case.fetch("response"))
           when "validate-sequence"
             sequence_valid?(test_case.fetch("requires"), test_case.fetch("responses"))
           else
             :unknown
           end
  expected = test_case.key?("valid") ? test_case.fetch("valid") : test_case.fetch("expected")
  if actual == :unknown
    "#{path}: unknown operation #{test_case['operation']}"
  elsif actual != expected
    "#{path}: #{test_case.fetch('name')} mismatch"
  end
end

if errors.empty?
  puts "Composition vectors OK"
else
  warn errors.join("\n")
  exit 1
end
