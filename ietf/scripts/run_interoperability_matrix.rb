#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "json"
require "net/http"
require "open3"
require "time"
require "timeout"
require "uri"

ROOT = File.expand_path("../..", __dir__)
PARENT = File.dirname(ROOT)
LANGUAGES = %w[node go java python rust].freeze
DISPLAY_NAMES = {
  "node" => "Node.js",
  "go" => "Go",
  "java" => "Java",
  "python" => "Python",
  "rust" => "Rust"
}.freeze
TIMEOUT_SECONDS = Integer(ENV.fetch("ODP_INTEROPERABILITY_TIMEOUT", "90"), 10)

directories = LANGUAGES.to_h do |language|
  variable = "ODP_#{language.upcase}_DIR"
  [language, File.expand_path(ENV.fetch(variable, File.join(PARENT, "odp-#{language}")))]
end
output_directory = File.expand_path(
  ENV.fetch("ODP_INTEROPERABILITY_OUTPUT", File.join(ROOT, ".interoperability/reports"))
)

def commands(directories, port)
  url = "http://127.0.0.1:#{port}"
  {
    "node" => {
      service: [{ "HOST" => "127.0.0.1", "PORT" => port.to_s },
                ["node", "examples/odp-service-small/dist/index.js"]],
      agent: [{}, ["node", "scripts/interoperability-agent.mjs", url]]
    },
    "go" => {
      service: [{}, ["go", "run", "./examples/odp-service-small", "-addr", "127.0.0.1:#{port}"]],
      agent: [{}, ["go", "run", "./cmd/odp-interoperability-agent", url]]
    },
    "java" => {
      service: [{ "PORT" => port.to_s },
                ["./mvnw", "--quiet", "--batch-mode", "--no-transfer-progress",
                 "-f", "examples/pom.xml",
                 "-Dexec.mainClass=org.offeringprotocol.odp.examples.SmallService",
                 "-Dexec.classpathScope=runtime", "org.codehaus.mojo:exec-maven-plugin:3.6.3:java"]],
      agent: [{}, ["./mvnw", "--quiet", "--batch-mode", "--no-transfer-progress",
                    "-f", "tools/odp-conformance/pom.xml",
                    "-Dexec.mainClass=org.offeringprotocol.odp.conformance.InteroperabilityAgent",
                    "-Dexec.args=#{url}", "-Dexec.classpathScope=runtime",
                    "org.codehaus.mojo:exec-maven-plugin:3.6.3:java"]]
    },
    "python" => {
      service: [{ "PORT" => port.to_s }, ["uv", "run", "python", "examples/service.py"]],
      agent: [{}, ["uv", "run", "python", "scripts/interoperability_agent.py", url]]
    },
    "rust" => {
      service: [{ "PORT" => port.to_s },
                ["cargo", "run", "--quiet", "--locked", "-p", "odp-examples",
                 "--bin", "odp-service-small"]],
      agent: [{}, ["cargo", "run", "--quiet", "--locked", "-p", "odp-conformance",
                    "--bin", "odp-interoperability-agent", "--", url]]
    }
  }.each_with_object({}) do |(language, value), result|
    result[language] = value.merge(directory: directories.fetch(language), url: url)
  end
end

def commit(directory)
  output, status = Open3.capture2("git", "rev-parse", "HEAD", chdir: directory)
  raise "Cannot identify SDK commit in #{directory}" unless status.success?

  output.strip
end

def wait_until_ready(url, process)
  deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + TIMEOUT_SECONDS
  loop do
    raise "Service exited before becoming ready" unless process.alive?

    begin
      response = Net::HTTP.start("127.0.0.1", URI(url).port, open_timeout: 1, read_timeout: 1) do |http|
        http.get("/.well-known/odp")
      end
      return if response.is_a?(Net::HTTPSuccess)
    rescue IOError, SystemCallError, Timeout::Error
      nil
    end
    raise "Service did not become ready within #{TIMEOUT_SECONDS} seconds" if
      Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline

    sleep 0.1
  end
end

def run_bounded(environment, command, directory)
  output = +""
  error = +""
  status = nil
  Open3.popen3(environment, *command, chdir: directory, pgroup: true) do |input, stdout, stderr, wait|
    input.close
    output_reader = Thread.new { stdout.read }
    error_reader = Thread.new { stderr.read }
    unless wait.join(TIMEOUT_SECONDS)
      Process.kill("TERM", -wait.pid)
      wait.join(5) || Process.kill("KILL", -wait.pid)
      raise "Agent timed out after #{TIMEOUT_SECONDS} seconds"
    end
    status = wait.value
    output = output_reader.value
    error = error_reader.value
  end
  [status.success?, output.strip, error.strip]
end

def stop_process(process)
  return unless process.alive?

  Process.kill("TERM", -process.pid)
  process.join(5) || Process.kill("KILL", -process.pid)
rescue Errno::ESRCH
  nil
end

def write_reports(output_directory, commits, cases)
  FileUtils.mkdir_p(output_directory)
  report = {
    generated_at: Time.now.utc.iso8601,
    implementations: commits,
    cases: cases
  }
  File.write(File.join(output_directory, "matrix.json"), "#{JSON.pretty_generate(report)}\n")

  rows = LANGUAGES.map do |agent|
    cells = LANGUAGES.map do |service|
      cases.find { |item| item[:agent] == agent && item[:service] == service }[:status] == "passed" ? "Pass" : "Fail"
    end
    "| #{DISPLAY_NAMES.fetch(agent)} | #{cells.join(' | ')} |"
  end
  failures = cases.reject { |item| item[:status] == "passed" }
  markdown = [
    "# ODP SDK Interoperability Matrix",
    "",
    "Generated at #{report[:generated_at]} against the implementation commits recorded in `matrix.json`.",
    "",
    "| Agent / Service | Node.js | Go | Java | Python | Rust |",
    "| --- | --- | --- | --- | --- | --- |",
    *rows,
    ""
  ]
  unless failures.empty?
    markdown.concat(["## Failures", ""])
    failures.each do |item|
      message = item[:message].to_s.lines.map(&:strip).reject(&:empty?).join(" ")
      markdown << "- #{item[:agent]} Agent → #{item[:service]} Service: #{message}"
    end
    markdown << ""
  end
  File.write(File.join(output_directory, "matrix.md"), "#{markdown.join("\n")}\n")
end

missing = directories.reject { |_language, directory| File.directory?(directory) }
raise "Missing SDK repositories: #{missing.values.join(', ')}" unless missing.empty?

commits = directories.transform_values { |directory| commit(directory) }
cases = []
LANGUAGES.each_with_index do |service, service_index|
  configuration = commands(directories, 46_100 + service_index).fetch(service)
  FileUtils.mkdir_p(output_directory)
  log_path = File.join(output_directory, "#{service}-service.log")
  File.open(log_path, "w") do |log|
    environment, command = configuration.fetch(:service)
    process = Process.spawn(environment, *command, chdir: configuration.fetch(:directory),
                            out: log, err: [:child, :out], pgroup: true)
    wait_thread = Process.detach(process)
    begin
      wait_until_ready(configuration.fetch(:url), wait_thread)
      LANGUAGES.each do |agent|
        started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        agent_configuration = commands(directories, 46_100 + service_index).fetch(agent)
        begin
          success, output, error = run_bounded(
            *agent_configuration.fetch(:agent), agent_configuration.fetch(:directory)
          )
          cases << {
            agent: agent,
            service: service,
            status: success ? "passed" : "failed",
            duration_ms: ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000).round,
            output: output,
            message: if success
                       nil
                     elsif !error.empty?
                       error
                     elsif !output.empty?
                       output
                     else
                       "Agent exited unsuccessfully"
                     end
          }.compact
        rescue StandardError => error
          cases << { agent: agent, service: service, status: "failed", message: error.message }
        end
      end
    rescue StandardError => error
      LANGUAGES.each do |agent|
        cases << { agent: agent, service: service, status: "failed", message: error.message }
      end
    ensure
      stop_process(wait_thread)
    end
  end
end

write_reports(output_directory, commits, cases)
failures = cases.count { |item| item[:status] != "passed" }
puts "ODP interoperability: #{cases.length - failures}/#{cases.length} pairings passed"
exit 1 unless failures.zero?
