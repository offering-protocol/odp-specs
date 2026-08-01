RUBY ?= ruby
MARKDOWN_FILES := $(shell find .. -type f -name '*.md' \
	-not -path '../.git/*' \
	-not -path '../artifacts/*' \
	-not -path '../ietf/vendor/*' \
	-not -path '../ietf/.venv/*' | sort)
DRAFTS := $(shell find specs -type f -name 'draft-*.md' | sort)

.PHONY: check check-drafts check-formatter check-format check-json check-examples format

check: check-drafts check-formatter check-format check-json check-examples

check-drafts:
	$(RUBY) scripts/check_drafts.rb $(DRAFTS)

check-formatter:
	$(RUBY) scripts/check_markdown_formatter.rb

check-format:
	$(RUBY) scripts/format_markdown.rb --check $(MARKDOWN_FILES)

check-json:
	$(RUBY) scripts/check_json.rb

check-examples:
	$(RUBY) scripts/check_examples.rb

format:
	$(RUBY) scripts/format_markdown.rb $(MARKDOWN_FILES)
