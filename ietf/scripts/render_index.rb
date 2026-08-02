#!/usr/bin/env ruby
# frozen_string_literal: true

require "cgi"
require "date"
require "pathname"
require "yaml"

check_only = ARGV.delete("--check")
draft_paths = ARGV[0...-1]
output = ARGV[-1]
abort "usage: render_index.rb [--check] DRAFT.md [DRAFT.md ...] OUTPUT.html" if draft_paths.empty? || output.nil?

RELEASE_BASE = "https://github.com/offering-protocol/odp-specs/releases/latest/download"
REPO_BASE = "https://github.com/offering-protocol/odp-specs"

def h(value)
  CGI.escapeHTML(value.to_s)
end

def draft_metadata(path)
  text = Pathname.new(path).read
  frontmatter = text.match(/\A---\n(.*?)\n\.\.\./m)
  abort "#{path}: missing YAML front matter" unless frontmatter

  metadata = YAML.safe_load(frontmatter[1], aliases: true, permitted_classes: [Date])
  abstract = text.match(/--- abstract\n\n(.*?)\n\n--- middle/m)&.[](1).to_s.gsub(/\s+/, " ").strip
  {
    docname: metadata.fetch("docname"),
    title: metadata.fetch("title"),
    description: abstract.match(/.*?[.!?](?:\s|$)/)&.[](0)&.strip || abstract
  }
end

def release_link(docname, extension)
  "#{RELEASE_BASE}/#{docname}.#{extension}"
end

draft_rows = draft_paths.map do |path|
  draft = draft_metadata(path)
  docname = draft.fetch(:docname)
  datatracker = "https://datatracker.ietf.org/doc/#{docname.sub(/-\d{2}\z/, '')}/"
  formats = %w[html txt xml pdf].map do |extension|
    "<a href=\"#{h(release_link(docname, extension))}\">#{extension.upcase}</a>"
  end.join(" ")
  <<~HTML
    <tr>
      <td><code>#{h(docname)}</code></td>
      <td>#{h(draft.fetch(:description))}</td>
      <td><a href="#{h(datatracker)}">IETF</a> #{formats}</td>
    </tr>
  HTML
end.join

resource_rows = [
  ["schemas/", "Protocol schemas", "Stable ODP wire-object JSON Schemas."],
  ["conformance/", "Conformance schemas", "Offline adapter, index, and report contracts."],
  ["examples/", "Descriptive examples", "Browsable scenarios with downloadable JSON artifacts."],
  ["problems/", "Problem Types", "Stable Problem Details type documentation."]
].map do |href, name, description|
  "<tr><td><a href=\"#{href}\">#{h(name)}</a></td><td>#{h(description)}</td></tr>"
end.join("\n")

html = <<~HTML
  <!doctype html>
  <html lang="en">
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <title>Offering Discovery Protocol Specifications</title>
      <style>
        :root { color-scheme: light dark; --bg: #f8fafc; --fg: #172033; --muted: #5b6475; --panel: #fff; --border: #d7dce5; --link: #0b5cad; }
        @media (prefers-color-scheme: dark) { :root { --bg: #10141c; --fg: #eef2f8; --muted: #aeb7c8; --panel: #171d28; --border: #2d3545; --link: #8ab8ff; } }
        * { box-sizing: border-box; }
        body { margin: 0; background: var(--bg); color: var(--fg); font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; line-height: 1.5; }
        main { width: min(960px, calc(100% - 32px)); margin: 0 auto; padding: 48px 0 64px; }
        h1 { margin: 0 0 8px; font-size: clamp(2rem, 6vw, 3.5rem); line-height: 1.05; }
        h2 { margin-top: 36px; }
        p { max-width: 760px; color: var(--muted); }
        a { color: var(--link); }
        table { width: 100%; border-collapse: collapse; background: var(--panel); border: 1px solid var(--border); }
        th, td { padding: 12px; border-bottom: 1px solid var(--border); text-align: left; vertical-align: top; }
        tbody tr:last-child td { border-bottom: none; }
        th { color: var(--muted); font-size: 0.9rem; }
        code { font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace; }
        td:last-child { white-space: nowrap; }
        @media (max-width: 640px) { table, tbody, tr, td { display: block; width: 100%; } thead { display: none; } tr { border-bottom: 1px solid var(--border); } td { border: 0; white-space: normal; } }
      </style>
    </head>
    <body>
      <main>
        <header>
          <h1>Offering Discovery Protocol Specifications</h1>
          <p>Internet-Draft sources, rendered specifications, and implementation-support artifacts for ODP.</p>
        </header>

        <h2>Current Draft</h2>
        <table>
          <thead><tr><th>Draft</th><th>Description</th><th>Formats</th></tr></thead>
          <tbody>#{draft_rows}</tbody>
        </table>

        <h2>Implementation Support</h2>
        <table>
          <thead><tr><th>Resource</th><th>Description</th></tr></thead>
          <tbody>#{resource_rows}</tbody>
        </table>

        <h2>Source</h2>
        <p>Sources and contribution guidance are maintained in the
          <a href="#{REPO_BASE}">offering-protocol/odp-specs</a> repository.</p>
      </main>
    </body>
  </html>
HTML

target = Pathname.new(output)
if check_only
  if target.file? && target.read == html
    puts "Published index OK"
  else
    warn "#{target}: missing or out of date"
    exit 1
  end
else
  target.dirname.mkpath
  target.write(html)
end
