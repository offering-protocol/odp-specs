#!/usr/bin/env ruby
# frozen_string_literal: true

LINE_WIDTH = 100
Align = Data.define(:left, :right)

def table_line?(line)
  stripped = line.strip
  stripped.start_with?("|") && stripped.end_with?("|")
end

def table_cells(line)
  line.strip.delete_prefix("|").delete_suffix("|").split("|", -1).map(&:strip)
end

def table_delimiter?(line)
  table_line?(line) && table_cells(line).all? { |cell| cell.match?(/\A:?-{3,}:?\z/) }
end

def table_delimiter(width, alignment)
  width = [width, 3].max
  return ":#{'-' * (width - 2)}:" if alignment.left && alignment.right
  return ":#{'-' * (width - 1)}" if alignment.left
  return "#{'-' * (width - 1)}:" if alignment.right

  "-" * width
end

def format_table(lines)
  rows = lines.map { |line| table_cells(line) }
  column_count = rows.map(&:length).max
  rows.each { |row| row.fill("", row.length...column_count) }

  alignments = table_cells(lines.fetch(1)).map do |cell|
    Align.new(left: cell.start_with?(":"), right: cell.end_with?(":"))
  end
  alignments.fill(Align.new(left: false, right: false), alignments.length...column_count)

  widths = Array.new(column_count, 3)
  rows.each_with_index do |row, row_index|
    next if row_index == 1

    row.each_with_index { |cell, column| widths[column] = [widths[column], cell.length].max }
  end

  rows.each_with_index.map do |row, row_index|
    cells = row.each_with_index.map do |cell, column|
      value = row_index == 1 ? table_delimiter(widths[column], alignments[column]) : cell.ljust(widths[column])
      " #{value} "
    end
    "|#{cells.join('|')}|"
  end
end

def wrap_words(text, first_prefix: "", continuation_prefix: "")
  words = text.split
  return [first_prefix.rstrip] if words.empty?

  lines = []
  prefix = first_prefix
  current = prefix.dup

  words.each do |word|
    separator = current == prefix ? "" : " "
    if current.length > prefix.length && current.length + separator.length + word.length > LINE_WIDTH
      lines << current
      prefix = continuation_prefix
      current = "#{prefix}#{word}"
    else
      current = "#{current}#{separator}#{word}"
    end
  end
  lines << current
  lines
end

def structural_line?(line)
  stripped = line.lstrip
  stripped.empty? ||
    stripped.start_with?("#", ">", "<", "<!--", "{:", "```", "~~~") ||
    stripped.match?(/\A(?:-{3,}|\*{3,}|_{3,})\s*\z/) ||
    stripped.match?(/\A\[[^\]]+\]:/) ||
    line.start_with?("    ", "\t") ||
    table_line?(line)
end

def list_item(line)
  match = line.match(/\A(\s*)([-+*]|\d+[.)])\s+(.+)\z/)
  return unless match

  prefix = "#{match[1]}#{match[2]} "
  [prefix, " " * prefix.length, match[3]]
end

def definition_item(line)
  match = line.match(/\A(\s*:\s+)(.+)\z/)
  return unless match

  [match[1], " " * match[1].length, match[2]]
end

def format_markdown(text)
  lines = text.lines(chomp: true)
  output = []
  index = 0
  fenced = false
  frontmatter = lines.first == "---"

  while index < lines.length
    line = lines[index]

    if frontmatter
      output << line
      index += 1
      frontmatter = false if index > 1 && ["---", "..."].include?(line)
      next
    end

    if line.lstrip.start_with?("```", "~~~")
      fenced = !fenced
      output << line
      index += 1
      next
    end

    if fenced
      output << line
      index += 1
      next
    end

    if index + 1 < lines.length && table_line?(line) && table_delimiter?(lines[index + 1])
      table = []
      while index < lines.length && table_line?(lines[index])
        table << lines[index]
        index += 1
      end
      output.concat(format_table(table))
      next
    end

    item = list_item(line) || definition_item(line)
    if item
      first_prefix, continuation_prefix, first_text = item
      parts = [first_text]
      index += 1
      while index < lines.length && !structural_line?(lines[index]) && !list_item(lines[index]) &&
            !definition_item(lines[index])
        parts << lines[index].strip
        index += 1
      end
      output.concat(wrap_words(parts.join(" "), first_prefix:, continuation_prefix:))
      next
    end

    if structural_line?(line)
      output << line.rstrip
      index += 1
      next
    end

    paragraph = []
    while index < lines.length && !structural_line?(lines[index]) && !list_item(lines[index]) &&
          !definition_item(lines[index])
      paragraph << lines[index].strip
      index += 1
    end
    output.concat(wrap_words(paragraph.join(" ")))
  end

  "#{output.join("\n")}\n"
end

if $PROGRAM_NAME == __FILE__
  check_only = ARGV.delete("--check")
  abort "usage: format_markdown.rb [--check] FILE [FILE ...]" if ARGV.empty?

  changed = []
  ARGV.each do |path|
    original = File.read(path)
    formatted = format_markdown(original)
    next if formatted == original

    if check_only
      changed << path
    else
      File.write(path, formatted)
    end
  end

  if check_only && changed.any?
    warn "Markdown formatting required:\n#{changed.join("\n")}"
    exit 1
  end

  puts check_only ? "Markdown formatting OK" : "Markdown formatted"
end
