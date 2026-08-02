RUBY ?= ruby
MARKDOWN_FILES := $(shell find .. -type f -name '*.md' \
	-not -path '../.git/*' \
	-not -path '../artifacts/*' \
	-not -path '../ietf/vendor/*' \
	-not -path '../ietf/.venv/*' | sort)
DRAFTS := $(shell find specs -type f -name 'draft-*.md' | sort)

.PHONY: check check-attribute-schemas check-collection-search check-collections check-drafts check-error-limits check-formatter check-format check-json check-examples check-identity check-offering-search check-offerings check-pagination check-representations check-service-document check-versioning format

check: check-drafts check-formatter check-format check-json check-attribute-schemas check-collection-search check-collections check-error-limits check-examples check-identity check-offering-search check-offerings check-pagination check-representations check-service-document check-versioning

check-attribute-schemas:
	$(RUBY) scripts/check_attribute_schema_vectors.rb

check-collection-search:
	$(RUBY) scripts/check_collection_search_vectors.rb

check-collections:
	$(RUBY) scripts/check_collection_vectors.rb

check-drafts:
	$(RUBY) scripts/check_drafts.rb $(DRAFTS)

check-error-limits:
	$(RUBY) scripts/check_error_limit_vectors.rb

check-formatter:
	$(RUBY) scripts/check_markdown_formatter.rb

check-format:
	$(RUBY) scripts/format_markdown.rb --check $(MARKDOWN_FILES)

check-json:
	$(RUBY) scripts/check_json.rb

check-examples:
	$(RUBY) scripts/check_examples.rb

check-identity:
	$(RUBY) scripts/check_identity_vectors.rb

check-offering-search:
	$(RUBY) scripts/check_offering_search_vectors.rb

check-offerings:
	$(RUBY) scripts/check_offering_vectors.rb

check-pagination:
	$(RUBY) scripts/check_pagination_vectors.rb

check-representations:
	$(RUBY) scripts/check_representation_vectors.rb

check-service-document:
	$(RUBY) scripts/check_service_document.rb

check-versioning:
	$(RUBY) scripts/check_versioning_vectors.rb

format:
	$(RUBY) scripts/format_markdown.rb $(MARKDOWN_FILES)
