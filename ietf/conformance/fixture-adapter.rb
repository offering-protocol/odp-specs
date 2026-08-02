#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"

status = ARGV.fetch(0, "passed")

$stdin.each_line do |line|
  request = JSON.parse(line)
  response = {
    "protocol_version" => "1",
    "sequence" => request.fetch("sequence"),
    "status" => status
  }
  puts JSON.generate(response)
end
