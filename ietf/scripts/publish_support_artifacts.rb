#!/usr/bin/env ruby
# frozen_string_literal: true

require "cgi"
require "fileutils"
require "json"
require "pathname"
require "rdoc"
require "rdoc/markdown"
require "rdoc/markup/to_html"

check_only = ARGV.delete("--check")
section = ARGV.shift || "all"
abort "usage: publish_support_artifacts.rb [--check] [all|conformance|schemas|examples|problems]" unless
  %w[all conformance schemas examples problems].include?(section) && ARGV.empty?

IETF_ROOT = Pathname.new(__dir__).join("..").expand_path
DOCS_ROOT = IETF_ROOT.join("..", "docs").expand_path
ORIGIN = "https://offeringprotocol.org"

def h(value)
  CGI.escapeHTML(value.to_s)
end

def page(title, introduction, body)
  <<~HTML
    <!doctype html>
    <html lang="en">
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>#{h(title)} - Offering Discovery Protocol</title>
        <style>
          :root { color-scheme: light dark; --bg: #f8fafc; --fg: #172033; --muted: #5b6475; --panel: #fff; --border: #d7dce5; --link: #0b5cad; --code: #f1f5f9; }
          @media (prefers-color-scheme: dark) { :root { --bg: #10141c; --fg: #eef2f8; --muted: #aeb7c8; --panel: #171d28; --border: #2d3545; --link: #8ab8ff; --code: #202735; } }
          body { margin: 0; background: var(--bg); color: var(--fg); font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; line-height: 1.55; }
          main { width: min(960px, calc(100% - 32px)); margin: 0 auto; padding: 48px 0 64px; }
          h1 { margin: 0 0 8px; font-size: clamp(2rem, 6vw, 3.2rem); line-height: 1.05; }
          h2 { margin-top: 32px; padding-top: 24px; border-top: 1px solid var(--border); }
          p { max-width: 780px; }
          .intro, .back { color: var(--muted); }
          .back { display: inline-block; margin-bottom: 24px; text-decoration: none; }
          a { color: var(--link); }
          table { width: 100%; border-collapse: collapse; background: var(--panel); border: 1px solid var(--border); }
          th, td { padding: 12px; border-bottom: 1px solid var(--border); text-align: left; vertical-align: top; }
          tbody tr:last-child td { border-bottom: none; }
          th { color: var(--muted); font-size: 0.9rem; }
          code, pre { font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace; }
          pre { padding: 14px; overflow-x: auto; background: var(--code); border: 1px solid var(--border); }
        </style>
      </head>
      <body>
        <main id="top">
          <h1>#{h(title)}</h1>
          <p class="intro">#{h(introduction)}</p>
          #{body}
        </main>
      </body>
    </html>
  HTML
end

def table(headers, rows)
  head = headers.map { |header| "<th>#{h(header)}</th>" }.join
  body = rows.map do |row|
    "<tr>#{row.map { |cell| "<td>#{cell}</td>" }.join}</tr>"
  end.join("\n")
  "<table><thead><tr>#{head}</tr></thead><tbody>#{body}</tbody></table>"
end

def schema_artifacts(source, publication_path, title, introduction)
  paths = source.children.select { |path| path.file? && path.basename.to_s.end_with?(".schema.json") }.sort
  abort "#{source}: no schema files found" if paths.empty?

  rows = paths.map do |path|
    schema = JSON.parse(path.read)
    name = path.basename.to_s
    expected_id = "#{ORIGIN}/#{publication_path}/#{name}"
    abort "#{path}: $id must be #{expected_id}" unless schema["$id"] == expected_id
    abort "#{path}: title is required" unless schema["title"].is_a?(String) && !schema["title"].empty?

    visit = lambda do |value|
      case value
      when Hash
        reference = value["$ref"]
        if reference.is_a?(String) && !reference.start_with?("#") && !reference.match?(/\A[a-z][a-z0-9+.-]*:/i)
          target_name = reference.split("#", 2).first
          target = source.join(target_name).cleanpath
          abort "#{path}: unresolved $ref #{reference}" unless target.file? && target.dirname == source
        end
        value.each_value { |child| visit.call(child) }
      when Array
        value.each { |child| visit.call(child) }
      end
    end
    visit.call(schema)

    ["<a href=\"#{h(name)}\"><code>#{h(name)}</code></a>", h(schema.fetch("title"))]
  end

  artifacts = paths.to_h { |path| [path.basename.to_s, path.read] }
  artifacts["index.html"] = page(
    title,
    introduction,
    table(%w[Schema Title], rows)
  )
  artifacts
end

def markdown_html(markdown)
  normalized = markdown.gsub(/\[`([^`]+)`\]\(([^)]+)\)/) do
    "[#{Regexp.last_match(1)}](#{Regexp.last_match(2)})"
  end
  document = RDoc::Markdown.parse(normalized)
  RDoc::Markup::ToHtml.new(RDoc::Options.new).convert(document)
end

def example_artifacts
  source = IETF_ROOT.join("examples")
  directories = source.children.select(&:directory?).sort
  rows = []
  artifacts = {}

  directories.each do |directory|
    readme = directory.join("README.md")
    abort "#{directory}: README.md is required" unless readme.file?

    markdown = readme.read
    title = markdown.lines.find { |line| line.start_with?("# ") }&.delete_prefix("# ")&.strip
    abort "#{readme}: top-level title is required" if title.to_s.empty?

    relative = directory.basename.to_s
    files = directory.children.select(&:file?).sort
    files.each { |path| artifacts["#{relative}/#{path.basename}"] = path.read }
    rendered_markdown = markdown.sub(/\A# .+\n/, "")
    artifacts["#{relative}/index.html"] = page(
      title,
      "A descriptive, non-normative ODP example.",
      "<a class=\"back\" href=\"../\">All examples</a>#{markdown_html(rendered_markdown)}"
    )
    rows << ["<a href=\"#{h(relative)}/\">#{h(title)}</a>", "#{files.count { |path| path.extname == '.json' }} JSON artifacts"]
  end

  artifacts["index.html"] = page(
    "ODP Examples",
    "Descriptive, non-normative scenarios and their directly downloadable JSON artifacts.",
    table(%w[Example Contents], rows)
  )
  artifacts
end

def problem_definitions
  draft = IETF_ROOT.join("specs", "draft-kavian-offering-discovery-protocol-01.md")
  source = draft.read.split("The initial core problem codes are:", 2).fetch(1, "")
  definitions = source.lines.filter_map do |line|
    match = line.match(/^\| `([A-Z][A-Z0-9_]*)`\s+\|\s+(\d{3})\s+\|\s+(.+?)\s+\|$/)
    next unless match

    { code: match[1], status: Integer(match[2]), meaning: match[3] }
  end
  abort "#{draft}: no core problem definitions found" if definitions.empty?
  definitions
end

def validate_problem_examples!(definitions)
  by_code = definitions.to_h { |definition| [definition.fetch(:code), definition] }
  errors = []
  Dir[IETF_ROOT.join("test-vectors", "**", "*.json")].sort.each do |path|
    visit = lambda do |value, location|
      case value
      when Hash
        next if value["operation"] == "validate-problem" && value["valid"] == false

        type = value["type"]
        code = value["code"]
        if type.is_a?(String) && type.start_with?("#{ORIGIN}/problems/") && code.is_a?(String)
          definition = by_code[code]
          expected_type = "#{ORIGIN}/problems/#{code.downcase.tr('_', '-')}"
          errors << "#{path}:#{location}: type must be #{expected_type}" unless type == expected_type
          if definition && value.key?("status") && value["status"] != definition.fetch(:status)
            errors << "#{path}:#{location}: status must be #{definition.fetch(:status)}"
          end
        end
        value.each { |key, child| visit.call(child, "#{location}.#{key}") }
      when Array
        value.each_with_index { |child, index| visit.call(child, "#{location}[#{index}]") }
      end
    end
    visit.call(JSON.parse(Pathname.new(path).read), "$")
  end
  abort errors.join("\n") unless errors.empty?
end

def problem_artifacts
  definitions = problem_definitions
  validate_problem_examples!(definitions)
  rows = []
  artifacts = {}

  definitions.each do |definition|
    code = definition.fetch(:code)
    slug = code.downcase.tr("_", "-")
    type = "#{ORIGIN}/problems/#{slug}"
    body = <<~HTML
      <a class="back" href="../">All ODP Problem Types</a>
      <dl>
        <dt>Type</dt><dd><code>#{h(type)}</code></dd>
        <dt>Code</dt><dd><code>#{h(code)}</code></dd>
        <dt>HTTP status</dt><dd>#{definition.fetch(:status)}</dd>
      </dl>
      <p>#{h(definition.fetch(:meaning))}</p>
      <p>The ODP Internet-Draft is normative. This page is generated from its core problem-code table.</p>
    HTML
    artifacts["#{slug}/index.html"] = page("ODP Problem: #{code}", definition.fetch(:meaning), body)
    rows << ["<a href=\"#{h(slug)}/\"><code>#{h(code)}</code></a>", definition.fetch(:status).to_s, h(definition.fetch(:meaning))]
  end

  artifacts["index.html"] = page(
    "ODP Problem Types",
    "Stable Problem Details type URLs defined by the Offering Discovery Protocol.",
    table(%w[Code Status Meaning], rows)
  )
  artifacts
end

def synchronize(destination, expected, check_only)
  existing = destination.directory? ? Dir[destination.join("**", "*")].select { |path| File.file?(path) }.map do |path|
    Pathname.new(path).relative_path_from(destination).to_s
  end : []
  errors = []

  expected.each do |relative, content|
    target = destination.join(relative)
    if check_only
      errors << "#{target}: missing" unless target.file?
      errors << "#{target}: out of date" if target.file? && target.read != content
    else
      FileUtils.mkdir_p(target.dirname)
      target.write(content)
    end
  end
  (existing - expected.keys).each do |relative|
    target = destination.join(relative)
    check_only ? errors << "#{target}: unexpected file" : target.delete
  end

  unless check_only
    Dir[destination.join("**", "*")].sort.reverse_each do |path|
      directory = Pathname.new(path)
      directory.rmdir if directory.directory? && directory.children.empty?
    end
  end
  errors
end

def link_errors(expected, section)
  expected.flat_map do |relative, content|
    next [] unless relative.end_with?(".html")

    content.scan(/href="([^"]+)"/).filter_map do |match|
      href = CGI.unescapeHTML(match.fetch(0))
      next if href.start_with?("#") || href.match?(/\A[a-z][a-z0-9+.-]*:/i)

      path = href.split(/[?#]/, 2).first
      target = Pathname.new(relative).dirname.join(path).cleanpath
      target = target.join("index.html") if path.end_with?("/")
      "docs/#{section}/#{relative}: unresolved link #{href}" unless expected.key?(target.to_s)
    end
  end
end

sections = {
  "conformance" => lambda {
    schema_artifacts(
      IETF_ROOT.join("conformance"),
      "conformance",
      "ODP Conformance Schemas",
      "JSON Schemas for the offline ODP conformance harness. These documents are not ODP wire objects."
    )
  },
  "schemas" => lambda {
    schema_artifacts(
      IETF_ROOT.join("schemas"),
      "schemas",
      "ODP JSON Schemas",
      "JSON Schemas for stable Offering Discovery Protocol wire objects. The Internet-Draft prose remains authoritative."
    )
  },
  "examples" => -> { example_artifacts },
  "problems" => -> { problem_artifacts }
}
selected = section == "all" ? sections : sections.slice(section)
errors = selected.flat_map do |name, generator|
  expected = generator.call
  link_errors(expected, name) + synchronize(DOCS_ROOT.join(name), expected, check_only)
end

if errors.empty?
  puts check_only ? "Published support artifacts OK" : "Support artifacts published"
else
  warn errors.join("\n")
  exit 1
end
