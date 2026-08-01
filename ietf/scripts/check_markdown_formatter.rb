#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "format_markdown"

def assert_equal(expected, actual, label)
  return if expected == actual

  warn "#{label} failed"
  warn "expected:\n#{expected.inspect}"
  warn "actual:\n#{actual.inspect}"
  exit 1
end

long_prose = "A paragraph with enough ordinary words to exceed the configured source width while remaining safe " \
             "for deterministic Markdown-aware wrapping without changing the meaning of the content."
wrapped = format_markdown("#{long_prose}\n")
abort "prose wrapping failed" unless wrapped.lines(chomp: true).all? { |line| line.length <= LINE_WIDTH }

table = <<~MARKDOWN
  | Name | Meaning |
  | --- | ---: |
  | short | a longer value |
MARKDOWN
expected_table = <<~MARKDOWN
  | Name  | Meaning        |
  | ----- | -------------: |
  | short | a longer value |
MARKDOWN
assert_equal(expected_table, format_markdown(table), "table alignment")

protected = <<~MARKDOWN
  ---
  title: "#{'x' * 120}"
  ...

  ```text
  #{'y' * 120}
  ```
MARKDOWN
assert_equal(protected, format_markdown(protected), "protected blocks")

ietf_source = <<~MARKDOWN
  ---
  title: "#{'x' * 120}"
  ...

  #{long_prose}
MARKDOWN
formatted_ietf_source = format_markdown(ietf_source)
abort "IETF front matter termination failed" unless formatted_ietf_source.lines.last(2).all? do |line|
  line.chomp.length <= LINE_WIDTH
end

list = "- #{Array.new(30, 'word').join(' ')}\n"
formatted_list = format_markdown(list)
abort "list indentation failed" unless formatted_list.lines.drop(1).all? { |line| line.start_with?("  ") }

assert_equal(wrapped, format_markdown(wrapped), "idempotence")

puts "Markdown formatter OK"
