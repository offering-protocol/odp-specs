#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "date"
require "net/http"
require "pathname"
require "uri"
require "yaml"

drafts = ARGV
abort "usage: prepare_references.rb DRAFT.md [DRAFT.md ...]" if drafts.empty?

CACHE = Pathname.new(__dir__).join("..", ".refcache").expand_path
ARCHIVE = "https://raw.githubusercontent.com/ietf-tools/bibxml-data-archive/main/bibxml"

references = drafts.flat_map do |draft|
  text = Pathname.new(draft).read
  frontmatter = text.match(/\A---\n(.*?)\n\.\.\./m)
  abort "#{draft}: missing YAML front matter" unless frontmatter

  metadata = YAML.safe_load(frontmatter[1], aliases: true, permitted_classes: [Date])
  keys = %w[normative informative].flat_map do |section|
    metadata.fetch(section, {}).filter_map { |key, value| key if value.nil? }
  end
  keys.concat(%w[RFC2119 RFC8174]) if text.include?("{::boilerplate bcp14")
  keys.grep(/\ARFC\d+\z/)
end.uniq.sort

FileUtils.mkdir_p(CACHE)
references.each do |reference|
  target = CACHE.join("reference.#{reference.sub('RFC', 'RFC.')}.xml")
  next if target.file? && !target.empty?

  uri = URI("#{ARCHIVE}/#{target.basename}")
  response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 20, read_timeout: 20) do |http|
    http.get(uri.request_uri)
  end
  abort "#{uri}: HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

  target.binwrite(response.body)
  puts "Cached #{reference}"
end
