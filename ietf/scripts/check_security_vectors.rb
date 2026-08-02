#!/usr/bin/env ruby
# frozen_string_literal: true

require "ipaddr"
require "json"
require "pathname"
require "uri"

NON_PUBLIC_RANGES = %w[
  0.0.0.0/8
  10.0.0.0/8
  100.64.0.0/10
  127.0.0.0/8
  169.254.0.0/16
  172.16.0.0/12
  192.0.0.0/24
  192.0.2.0/24
  192.168.0.0/16
  198.18.0.0/15
  198.51.100.0/24
  203.0.113.0/24
  224.0.0.0/4
  240.0.0.0/4
  ::/128
  ::1/128
  fc00::/7
  fe80::/10
  ff00::/8
  2001:db8::/32
].map { |range| IPAddr.new(range) }.freeze

SENSITIVE_FIELDS = %w[authorization aep-authorization cookie payment-signature].freeze
LOCAL_HOSTS = %w[localhost 127.0.0.1 ::1 [::1]].freeze

def non_public?(address)
  ip = IPAddr.new(address)
  NON_PUBLIC_RANGES.any? { |range| range.include?(ip) }
rescue IPAddr::InvalidAddressError
  true
end

def destination_valid?(test_case)
  uri = URI.parse(test_case.fetch("url"))
  addresses = test_case.fetch("resolved_addresses")
  peer = test_case.fetch("connected_address")
  local = test_case.fetch("local_development") && LOCAL_HOSTS.include?(uri.host)
  return false unless uri.is_a?(URI::HTTPS) || (uri.is_a?(URI::HTTP) && local)
  return false unless addresses.is_a?(Array) && !addresses.empty? && addresses.uniq.length == addresses.length
  return addresses.all? { |address| non_public?(address) } && addresses.include?(peer) if local

  addresses.none? { |address| non_public?(address) } && addresses.include?(peer) && !non_public?(peer)
rescue URI::InvalidURIError
  false
end

def origin(uri_string)
  uri = URI.parse(uri_string)
  port = uri.port || (uri.scheme == "https" ? 443 : 80)
  [uri.scheme, uri.host&.downcase, port]
end

def forwarded_sensitive_fields(test_case)
  return [] if test_case.fetch("request_kind") == "supporting-document" || !test_case.fetch("same_origin")

  test_case.fetch("input_fields").select { |field| SENSITIVE_FIELDS.include?(field.downcase) }
end

path = Pathname.new(__dir__).join("..", "test-vectors", "security", "contract.json").expand_path
vector = JSON.parse(path.read)
errors = vector.fetch("cases").filter_map do |test_case|
  actual = case test_case.fetch("operation")
           when "validate-destination"
             destination_valid?(test_case)
           when "validate-redirect"
             origin(test_case.fetch("from")) == origin(test_case.fetch("to"))
           when "forwarded-sensitive-fields"
             forwarded_sensitive_fields(test_case)
           when "action-invocable"
             test_case.fetch("explicitly_selected")
           when "payment-authorized"
             test_case.fetch("live_challenge") && test_case.fetch("caller_policy_approved")
           when "cache-reusable"
             %w[same_url same_method same_representation_inputs same_authentication_context].all? do |field|
               test_case.fetch(field)
             end
           end
  expected = test_case.key?("expected") ? test_case.fetch("expected") : test_case.fetch("valid")
  "#{path}: #{test_case.fetch('name')} mismatch" unless actual == expected
end

if errors.empty?
  puts "Security vectors OK"
else
  warn errors.join("\n")
  exit 1
end
