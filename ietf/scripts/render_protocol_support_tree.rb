#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"

check_only = ARGV.delete("--check")
output = ARGV.shift
abort "usage: render_protocol_support_tree.rb [--check] OUTPUT" unless output && ARGV.empty?

IETF_ROOT = Pathname.new(__dir__).join("..").expand_path
ASSET_PATH = '#{offeringAssetPath}'
GITHUB_ROOT = "https://github.com/offering-protocol/odp-specs"
LOCAL_PATH = '#{offeringPath}'

def humanize(value)
  value.tr("-_", "  ").split.map(&:capitalize).join(" ")
end

def item(label, links, children = [])
  arguments = [label, links, ASSET_PATH].map { |value| JSON.generate(value) }
  options = ["nested=true"]
  options.concat(["folder=true", "collapsed=true"]) unless children.empty?
  rendered = "{{- protocolTocItem(#{(arguments + options).join(', ')}) -}}"
  unless children.empty?
    rendered += "\n  {{- openUl(\"protocol-toc-children\") -}}\n"
    rendered += children.map { |child| child.lines.map { |line| "    #{line}" }.join }.join
    rendered += "  {{- closeUl() -}}\n"
  end
  "#{rendered}{{- protocolTocItemEnd() -}}\n"
end

def problem_definitions
  draft = IETF_ROOT.join("specs", "draft-kavian-offering-discovery-protocol-01.md")
  source = draft.read.split("The initial core problem codes are:", 2).fetch(1, "")
  definitions = source.lines.filter_map do |line|
    match = line.match(/^\| `([A-Z][A-Z0-9_]*)`\s+\|\s+\d{3}\s+\|\s+(.+?)\s+\|$/)
    next unless match

    [match[1], match[2]]
  end
  abort "#{draft}: no core problem definitions found" if definitions.empty?

  definitions
end

def schema_children(source, publication_path)
  source.children.select { |path| path.file? && path.basename.to_s.end_with?(".schema.json") }.sort.map do |path|
    name = path.basename.to_s
    item(name, [["open", "#{LOCAL_PATH}/#{publication_path}/#{name}", false]])
  end
end

sections = []
sections << item(
  "Protocol Schemas",
  [["browse", "#{LOCAL_PATH}/schemas/", false], ["github", "#{GITHUB_ROOT}/tree/main/ietf/schemas"]],
  schema_children(IETF_ROOT.join("schemas"), "schemas")
)
sections << item(
  "Conformance",
  [["browse", "#{LOCAL_PATH}/conformance/", false], ["github", "#{GITHUB_ROOT}/tree/main/ietf/conformance"]],
  schema_children(IETF_ROOT.join("conformance"), "conformance")
)

test_vector_children = IETF_ROOT.join("test-vectors").children.select(&:directory?).sort.map do |directory|
  name = directory.basename.to_s
  item(humanize(name), [["browse", "#{LOCAL_PATH}/test-vectors/#{name}/", false]])
end
sections << item("Test Vectors", [["browse", "#{LOCAL_PATH}/test-vectors/", false], ["github", "#{GITHUB_ROOT}/tree/main/ietf/test-vectors"]], test_vector_children)

example_children = IETF_ROOT.join("examples").children.select(&:directory?).sort.map do |directory|
  readme = directory.join("README.md")
  title = readme.read.lines.find { |line| line.start_with?("# ") }&.delete_prefix("# ")&.strip
  abort "#{readme}: top-level title is required" if title.to_s.empty?

  name = directory.basename.to_s
  item(title, [["browse", "#{LOCAL_PATH}/examples/#{name}/", false]])
end
sections << item("Examples", [["browse", "#{LOCAL_PATH}/examples/", false], ["github", "#{GITHUB_ROOT}/tree/main/ietf/examples"]], example_children)

problem_children = problem_definitions.map do |code, _meaning|
  slug = code.downcase.tr("_", "-")
  item(code, [["browse", "#{LOCAL_PATH}/problems/#{slug}/", false]])
end
sections << item(
  "Problem Types",
  [["browse", "#{LOCAL_PATH}/problems/", false], ["github", "#{GITHUB_ROOT}/blob/main/ietf/specs/draft-kavian-offering-discovery-protocol-01.md#problem-details"]],
  problem_children
)

rendered = sections.join
target = Pathname.new(output).expand_path
if check_only
  abort "#{target}: missing" unless target.file?
  abort "#{target}: out of date" unless target.read == rendered

  puts "Published protocol support tree OK"
else
  target.dirname.mkpath
  target.write(rendered)
  puts "Protocol support tree published"
end
