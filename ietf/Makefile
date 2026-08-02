RUBY ?= ruby
OUTPUT ?= /tmp/odp-marketplace-scale
MARKDOWN_FILES := $(shell find .. -type f -name '*.md' \
	-not -path '../.git/*' \
	-not -path '../artifacts/*' \
	-not -path '../ietf/vendor/*' \
	-not -path '../ietf/.venv/*' | sort)
DRAFTS := $(shell find specs -type f -name 'draft-*.md' | sort)

.PHONY: check check-attribute-schemas check-collection-search check-collections check-composition check-drafts check-error-limits check-filters-sorting check-formatter check-format check-json check-examples check-identity check-marketplace-scale check-offering-search check-offerings check-pagination check-refinements check-representations check-search-capabilities check-service-document check-versioning format generate-marketplace-scale

check: check-drafts check-formatter check-format check-json check-attribute-schemas check-collection-search check-collections check-composition check-error-limits check-examples check-filters-sorting check-identity check-marketplace-scale check-offering-search check-offerings check-pagination check-refinements check-representations check-search-capabilities check-service-document check-versioning

check-attribute-schemas:
	$(RUBY) scripts/check_attribute_schema_vectors.rb

check-collection-search:
	$(RUBY) scripts/check_collection_search_vectors.rb

check-collections:
	$(RUBY) scripts/check_collection_vectors.rb

check-composition:
	$(RUBY) scripts/check_composition_vectors.rb

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

check-filters-sorting:
	$(RUBY) scripts/check_filter_sort_vectors.rb

check-identity:
	$(RUBY) scripts/check_identity_vectors.rb

check-marketplace-scale:
	$(RUBY) scripts/check_marketplace_scale.rb

check-offering-search:
	$(RUBY) scripts/check_offering_search_vectors.rb

check-offerings:
	$(RUBY) scripts/check_offering_vectors.rb

check-pagination:
	$(RUBY) scripts/check_pagination_vectors.rb

check-refinements:
	$(RUBY) scripts/check_refinement_vectors.rb

check-representations:
	$(RUBY) scripts/check_representation_vectors.rb

check-search-capabilities:
	$(RUBY) scripts/check_search_capability_vectors.rb

check-service-document:
	$(RUBY) scripts/check_service_document.rb

check-versioning:
	$(RUBY) scripts/check_versioning_vectors.rb

generate-marketplace-scale:
	$(RUBY) scripts/check_marketplace_scale.rb --output "$(OUTPUT)"

format:
	$(RUBY) scripts/format_markdown.rb $(MARKDOWN_FILES)
