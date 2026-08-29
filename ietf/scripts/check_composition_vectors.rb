#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"

PAYMENT_OPTIONS = %w[
  algorand aptos arbitrum avalanche base card ethereum hedera inflow lightning polygon solana
  stellar stripe tempo ton
].freeze

def advertisement_valid?(protocols)
  return false unless protocols.is_a?(Hash) && !protocols.empty?
  return false unless (protocols.keys - %w[enrollment payments trust]).empty?
  return false if protocols.key?("enrollment") && protocols["enrollment"] != [{ "name" => "aep" }]
  return false if protocols.key?("trust") && protocols["trust"] != [{ "name" => "tap" }]

  payments = protocols["payments"]
  return false if payments &&
    (!payments.is_a?(Array) || payments.empty? || payments.length > 2 ||
      payments.any? do |payment|
        !payment.is_a?(Hash) || (payment.keys - %w[authentication name options]).any? ||
          !%w[authentication name].all? { |key| payment.key?(key) } ||
          !%w[not-required required].include?(payment["authentication"]) || !%w[mpp x402].include?(payment["name"]) ||
          (payment.key?("options") &&
            (!payment["options"].is_a?(Array) || !payment["options"].length.between?(1, 16) ||
              payment["options"].uniq.length != payment["options"].length ||
              payment["options"].any? { |option| !PAYMENT_OPTIONS.include?(option) }))
      end || payments.map { |payment| payment["name"] }.uniq.length != payments.length)

  return false if payments&.any? { |payment| payment["authentication"] == "required" } && !protocols.key?("enrollment")

  protocols.key?("enrollment") || protocols.key?("payments") || protocols.key?("trust")
end

def recognized_protocols(protocols)
  recognized = {}
  enrollment = protocols["enrollment"]&.select { |descriptor| descriptor.is_a?(Hash) && descriptor["name"] == "aep" }
  payments = protocols["payments"]&.select do |descriptor|
    descriptor.is_a?(Hash) && %w[mpp x402].include?(descriptor["name"]) &&
      (!descriptor["authentication"].is_a?(String) ||
        %w[not-required optional required].include?(descriptor["authentication"]))
  end
  trust = protocols["trust"]&.select { |descriptor| descriptor.is_a?(Hash) && descriptor["name"] == "tap" }
  recognized["enrollment"] = enrollment unless enrollment.nil? || enrollment.empty?
  recognized["payments"] = payments unless payments.nil? || payments.empty?
  recognized["trust"] = trust unless trust.nil? || trust.empty?
  recognized
end

def filter_named_list(document, member, names)
  return unless document[member].is_a?(Array)

  document[member] = document[member].select do |item|
    !item.is_a?(Hash) || !item["name"].is_a?(String) || names.include?(item["name"])
  end
  document.delete(member) if document[member].empty?
end

def filter_typed_list(document, member, types)
  return unless document[member].is_a?(Array)

  document[member] = document[member].select do |item|
    !item.is_a?(Hash) || !item["type"].is_a?(String) || types.include?(item["type"])
  end
  document.delete(member) if document[member].empty?
end

def known_filter?(definition)
  return true unless definition.is_a?(Hash)
  return false if definition["type"].is_a?(String) &&
    !%w[boolean date date-time decimal integer number string].include?(definition["type"])
  return false if definition["operators"].is_a?(Array) && definition["operators"].any? do |operator|
    operator.is_a?(String) && !%w[eq exists gt gte in lt lte].include?(operator)
  end

  unit = definition["unit"]
  !unit.is_a?(Hash) || !unit["system"].is_a?(String) || %w[service ucum].include?(unit["system"])
end

def known_sort?(definition)
  return true unless definition.is_a?(Hash) && definition["keys"].is_a?(Array)

  definition["keys"].none? do |key|
    key.is_a?(Hash) &&
      ((key["direction"].is_a?(String) && !%w[ascending descending].include?(key["direction"])) ||
       (key["missing"].is_a?(String) && !%w[first last].include?(key["missing"])))
  end
end

def normalize_agent_response(value, kind)
  document = Marshal.load(Marshal.dump(value))
  if kind == "service-document"
    document["protocols"] = recognized_protocols(document["protocols"]) if document["protocols"].is_a?(Hash)
    document.delete("protocols") if document["protocols"] == {}
    filter_named_list(document, "operations", %w[get-collection get-offering list-collection-offerings list-collections list-offerings search-collections search-offerings])
    document["operations"]&.select! do |item|
      !item.is_a?(Hash) || !item["authentication"].is_a?(String) ||
        %w[not-required optional required].include?(item["authentication"])
    end
    filter_typed_list(document, "mcp", ["streamable-http"])
    document["operations"]&.select! { |item| !item.is_a?(Hash) || (item.keys - %w[authentication name]).empty? }
    document["mcp"]&.select! { |item| !item.is_a?(Hash) || (item.keys - %w[description name type url]).empty? }
    if document["branding"].is_a?(Hash)
      document["branding"].select! { |member, _image| %w[icon logo].include?(member) }
      document["branding"].delete_if do |_member, image|
        image.is_a?(Hash) && image["type"].is_a?(String) &&
          !%w[image/png image/svg+xml image/webp].include?(image["type"])
      end
      document["branding"].each_value do |image|
        image.select! { |key, _value| %w[src type].include?(key) } if image.is_a?(Hash)
      end
      document.delete("branding") if document["branding"].empty?
    end
    if document["search_capabilities"].is_a?(Hash)
      { "filters" => method(:known_filter?), "sorts" => method(:known_sort?) }.each do |member, predicate|
        source = document.dig("search_capabilities", member)
        next unless source.is_a?(Hash) && source["inline"].is_a?(Array)

        source["inline"] = source["inline"].select { |item| predicate.call(item) }
        document["search_capabilities"].delete(member) if source["inline"].empty?
      end
      document.delete("search_capabilities") if document["search_capabilities"].empty?
    end
    document.dig("protocols", "payments")&.each do |payment|
      next unless payment.is_a?(Hash) && payment["options"].is_a?(Array)

      payment["options"] = payment["options"].select { |option| !option.is_a?(String) || PAYMENT_OPTIONS.include?(option) }
      payment.delete("options") if payment["options"].empty?
    end
  elsif kind == "offering"
    filter_typed_list(document, "images", %w[image/avif image/jpeg image/png image/svg+xml image/webp])
    document["images"]&.each { |image| image.select! { |key, _value| %w[alt height src type width].include?(key) } if image.is_a?(Hash) }
    document.delete("schema") if document["schema"].is_a?(Hash) && (document["schema"].keys - ["url"]).any?
    if document["price"].is_a?(Hash) && document.dig("price", "type").is_a?(String) &&
       !%w[fixed free metered quote range starting_at].include?(document.dig("price", "type"))
      document.delete("price")
    end
    if document["actions"].is_a?(Array)
      document["actions"] = document["actions"].select do |action|
        method = action.dig("http", "method") if action.is_a?(Hash)
        next true unless action.is_a?(Hash)
        next false if action["authentication"].is_a?(String) &&
          !%w[not-required optional required].include?(action["authentication"])
        next false unless (action.keys - %w[authentication description http id openapi rel]).empty?
        next false if action["http"].is_a?(Hash) &&
          (action["http"].keys - %w[href method request response_content_types]).any?

        !method.is_a?(String) || %w[GET POST].include?(method)
      end
      document.delete("actions") if document["actions"].empty?
    end
  elsif %w[filter-page sort-page].include?(kind) && document["items"].is_a?(Array)
    predicate = kind == "filter-page" ? method(:known_filter?) : method(:known_sort?)
    document["items"] = document["items"].select { |item| predicate.call(item) }
  elsif kind == "problem" && document["invalid_params"].is_a?(Array)
    document["invalid_params"] = document["invalid_params"].select do |parameter|
      !parameter.is_a?(Hash) || !parameter["in"].is_a?(String) ||
        %w[body header path query].include?(parameter["in"])
    end
  end
  document
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
           when "filter-advertisement"
             recognized_protocols(test_case.fetch("protocols"))
           when "normalize-agent-response"
             normalize_agent_response(test_case.fetch("document"), test_case.fetch("kind"))
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
