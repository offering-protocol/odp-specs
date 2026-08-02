#!/usr/bin/env ruby
# frozen_string_literal: true

require "digest"
require "json"
require "pathname"
require "time"

module ConformanceHarness
  PROTOCOL_VERSION = "1"
  ROLES = %w[agent service].freeze
  STATUSES = %w[passed failed skipped].freeze
  VECTOR_FIELDS = %w[id title description drafts category applies_to subject cases].freeze
  REQUIRED_VECTOR_FIELDS = %w[id title drafts category applies_to subject cases].freeze

  module_function

  def load_vectors(root, selected_suites)
    index_path = root.join("index.json")
    index = JSON.parse(index_path.read)
    validate_index!(index, root)

    vectors = index.fetch("vectors").map do |relative_path|
      path = root.join(relative_path)
      [relative_path, JSON.parse(path.read)]
    end
    vectors.select! { |_, vector| selected_suites.include?(vector.fetch("category")) } unless selected_suites.empty?
    [index, vectors]
  end

  def validate_index!(index, root)
    raise "index_version must be #{PROTOCOL_VERSION}" unless index == {
      "index_version" => PROTOCOL_VERSION,
      "vectors" => index["vectors"]
    }

    paths = index.fetch("vectors")
    raise "vectors must be a non-empty array" unless paths.is_a?(Array) && !paths.empty?
    raise "vector paths must be sorted and unique" unless paths == paths.sort.uniq

    indexed = paths.map { |path| root.join(path).cleanpath }
    raise "vector path escapes the vector root" unless indexed.all? { |path| path.to_s.start_with?("#{root.cleanpath}/") }
    raise "indexed vector is missing" unless indexed.all?(&:file?)

    discovered = Dir[root.join("*", "*.json")].map { |path| Pathname.new(path).relative_path_from(root).to_s }.sort
    raise "vector index does not match discovered vectors" unless paths == discovered

    ids = indexed.each_with_index.map do |path, index|
      vector = JSON.parse(path.read)
      validate_vector!(vector)
      category = paths.fetch(index).split("/").first
      raise "vector category does not match its index path" unless vector.fetch("category") == category

      vector.fetch("id")
    end
    raise "vector identifiers must be unique" unless ids == ids.uniq
  end

  def validate_vector!(vector)
    raise "vector fields are invalid" unless vector.is_a?(Hash) && (vector.keys - VECTOR_FIELDS).empty?
    raise "vector metadata is incomplete" unless REQUIRED_VECTOR_FIELDS.all? { |field| vector.key?(field) }
    raise "vector strings are invalid" unless %w[id title category subject].all? do |field|
      vector[field].is_a?(String) && !vector[field].empty?
    end
    raise "vector drafts are invalid" unless vector["drafts"].is_a?(Array) && !vector["drafts"].empty? &&
      vector["drafts"] == vector["drafts"].uniq && vector["drafts"].all? { |draft| draft.is_a?(String) && !draft.empty? }
    raise "vector applies_to is invalid" unless vector["applies_to"].is_a?(Array) &&
      !vector["applies_to"].empty? && vector["applies_to"] == vector["applies_to"].uniq &&
      (vector["applies_to"] - ROLES).empty?
    raise "vector cases are invalid" unless vector["cases"].is_a?(Array) && !vector["cases"].empty?

    names = vector["cases"].map { |test_case| test_case["name"] if test_case.is_a?(Hash) }
    raise "vector case names are invalid" unless names.all? { |name| name.is_a?(String) && !name.empty? } && names == names.uniq
  end

  def revision(index, vectors)
    digest = Digest::SHA256.new
    digest << JSON.generate("index_version" => index.fetch("index_version"))
    vectors.each do |path, vector|
      digest << path
      digest << JSON.generate(vector)
    end
    "sha256:#{digest.hexdigest}"
  end

  def requests(vectors, role)
    sequence = 0
    vectors.flat_map do |_, vector|
      next [] unless vector.fetch("applies_to").include?(role)

      metadata = vector.slice("id", "title", "drafts", "category", "subject")
      vector.fetch("cases").filter_map do |test_case|
        next if test_case.key?("role") && test_case.fetch("role") != role

        sequence += 1
        {
          "protocol_version" => PROTOCOL_VERSION,
          "sequence" => sequence,
          "role" => role,
          "vector" => metadata,
          "case" => test_case
        }
      end
    end
  end

  def validate_response!(response, expected_sequences)
    allowed = %w[protocol_version sequence status message]
    raise "adapter response must be an object" unless response.is_a?(Hash)
    raise "adapter response contains unknown fields" unless (response.keys - allowed).empty?
    raise "adapter response protocol_version is invalid" unless response["protocol_version"] == PROTOCOL_VERSION
    raise "adapter response sequence is invalid" unless expected_sequences.include?(response["sequence"])
    raise "adapter response status is invalid" unless STATUSES.include?(response["status"])
    return unless response.key?("message")

    message = response["message"]
    raise "adapter response message is invalid" unless message.is_a?(String) && message.length.between?(1, 1024)
  end

  def report(name:, version:, role:, vector_revision:, requests:, responses:)
    categories = requests.group_by { |request| request.dig("vector", "category") }
    suites = categories.map do |category, category_requests|
      statuses = category_requests.map { |request| responses.fetch(request.fetch("sequence")).fetch("status") }
      {
        "category" => category,
        "passed" => statuses.count("passed"),
        "failed" => statuses.count("failed"),
        "skipped" => statuses.count("skipped")
      }
    end

    report = {
      "report_version" => PROTOCOL_VERSION,
      "generated_at" => Time.now.utc.iso8601,
      "implementation" => { "name" => name, "version" => version },
      "role" => role,
      "odp_version" => "1.0",
      "vector_revision" => vector_revision,
      "suites" => suites
    }
    validate_report!(report)
    report
  end

  def validate_report!(report)
    fields = %w[report_version generated_at implementation role odp_version vector_revision suites]
    raise "report fields are invalid" unless report.is_a?(Hash) && report.keys.sort == fields.sort
    raise "report_version is invalid" unless report["report_version"] == PROTOCOL_VERSION
    begin
      Time.iso8601(report.fetch("generated_at"))
    rescue ArgumentError
      raise "report generated_at is invalid"
    end
    raise "report role is invalid" unless ROLES.include?(report["role"])
    raise "report odp_version is invalid" unless report["odp_version"] == "1.0"
    revision = report["vector_revision"]
    raise "report vector_revision is invalid" unless revision.is_a?(String) && revision.length.between?(1, 128)

    implementation = report["implementation"]
    raise "report implementation is invalid" unless implementation.is_a?(Hash) &&
      implementation.keys.sort == %w[name version] && implementation.values.all? do |value|
        value.is_a?(String) && value.length.between?(1, 128)
      end

    suites = report["suites"]
    raise "report suites are invalid" unless suites.is_a?(Array) && !suites.empty?
    suites.each do |suite|
      raise "report suite fields are invalid" unless suite.is_a?(Hash) &&
        suite.keys.sort == %w[category failed passed skipped]
      raise "report suite category is invalid" unless suite["category"].is_a?(String) &&
        suite["category"].length.between?(1, 64)
      raise "report suite counts are invalid" unless %w[passed failed skipped].all? do |field|
        suite[field].is_a?(Integer) && suite[field] >= 0
      end
    end
  end
end
