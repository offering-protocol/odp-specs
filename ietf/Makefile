RUBY ?= ruby
OUTPUT ?= /tmp/odp-marketplace-scale
ARTIFACTS := ../artifacts
INDEX_ARTIFACT := ../docs/index.html
KRAMDOWN_RFC := bundle exec kramdown-rfc
XML2RFC := .venv/bin/xml2rfc
XML2RFC_CACHE := .cache/xml2rfc
IDNITS := idnits
MARKDOWN_FILES := $(shell find .. -type f -name '*.md' \
	-not -path '../.git/*' \
	-not -path '../artifacts/*' \
	-not -path '../docs/*' \
	-not -path '../ietf/vendor/*' \
	-not -path '../ietf/.venv/*' | sort)
DRAFTS := $(shell find specs -type f -name 'draft-*.md' | sort)

.PHONY: check check-actions check-attribute-schemas check-collection-search check-collections check-composition check-conformance check-drafts check-error-limits check-external-section-refs check-filters-sorting check-formatter check-format check-harness check-index check-json check-examples check-identity check-marketplace-scale check-offering-search check-offerings check-pagination check-published-support check-refinements check-representations check-search-capabilities check-security check-service-document check-versioning clean format generate-marketplace-scale idnits prepare-references render render-drafts render-examples render-index render-problems render-schemas render-support

check: check-drafts check-external-section-refs check-formatter check-format check-json check-actions check-attribute-schemas check-collection-search check-collections check-composition check-conformance check-error-limits check-examples check-filters-sorting check-harness check-identity check-index check-marketplace-scale check-offering-search check-offerings check-pagination check-published-support check-refinements check-representations check-search-capabilities check-security check-service-document check-versioning

check-actions:
	$(RUBY) scripts/check_action_vectors.rb

check-attribute-schemas:
	$(RUBY) scripts/check_attribute_schema_vectors.rb

check-collection-search:
	$(RUBY) scripts/check_collection_search_vectors.rb

check-collections:
	$(RUBY) scripts/check_collection_vectors.rb

check-composition:
	$(RUBY) scripts/check_composition_vectors.rb

check-conformance:
	$(RUBY) scripts/check_conformance_vectors.rb

check-drafts:
	$(RUBY) scripts/check_drafts.rb $(DRAFTS)

check-error-limits:
	$(RUBY) scripts/check_error_limit_vectors.rb

check-external-section-refs:
	$(RUBY) scripts/check_external_section_refs.rb $(DRAFTS)

check-formatter:
	$(RUBY) scripts/check_markdown_formatter.rb

check-format:
	$(RUBY) scripts/format_markdown.rb --check $(MARKDOWN_FILES)

check-harness:
	$(RUBY) scripts/check_conformance_harness.rb

check-json:
	$(RUBY) scripts/check_json.rb

check-examples:
	$(RUBY) scripts/check_examples.rb

check-filters-sorting:
	$(RUBY) scripts/check_filter_sort_vectors.rb

check-identity:
	$(RUBY) scripts/check_identity_vectors.rb

check-index:
	$(RUBY) scripts/render_index.rb --check $(DRAFTS) "$(INDEX_ARTIFACT)"

check-marketplace-scale:
	$(RUBY) scripts/check_marketplace_scale.rb

check-offering-search:
	$(RUBY) scripts/check_offering_search_vectors.rb

check-offerings:
	$(RUBY) scripts/check_offering_vectors.rb

check-pagination:
	$(RUBY) scripts/check_pagination_vectors.rb

check-published-support:
	$(RUBY) scripts/publish_support_artifacts.rb --check

check-refinements:
	$(RUBY) scripts/check_refinement_vectors.rb

check-representations:
	$(RUBY) scripts/check_representation_vectors.rb

check-search-capabilities:
	$(RUBY) scripts/check_search_capability_vectors.rb

check-security:
	$(RUBY) scripts/check_security_vectors.rb

check-service-document:
	$(RUBY) scripts/check_service_document.rb

check-versioning:
	$(RUBY) scripts/check_versioning_vectors.rb

generate-marketplace-scale:
	$(RUBY) scripts/check_marketplace_scale.rb --output "$(OUTPUT)"

format:
	$(RUBY) scripts/format_markdown.rb $(MARKDOWN_FILES)

render: render-drafts render-support render-index

prepare-references:
	$(RUBY) scripts/prepare_references.rb $(DRAFTS)

render-drafts: prepare-references
	@$(KRAMDOWN_RFC) --version >/dev/null || { echo "kramdown-rfc is required for render; run bundle install"; exit 1; }
	@test -x "$(XML2RFC)" || { echo "xml2rfc is required for render; run python3 -m venv .venv && .venv/bin/python -m pip install -r requirements.txt"; exit 1; }
	@mkdir -p "$(ARTIFACTS)" "$(XML2RFC_CACHE)"
	@for draft in $(DRAFTS); do \
		docname=$$(basename "$$draft" .md); \
		$(KRAMDOWN_RFC) "$$draft" > "$(ARTIFACTS)/$$docname.xml"; \
		$(XML2RFC) --cache "$(XML2RFC_CACHE)" --text --html --pdf --path "$(ARTIFACTS)" "$(ARTIFACTS)/$$docname.xml"; \
	done

render-examples:
	$(RUBY) scripts/publish_support_artifacts.rb examples

render-index:
	$(RUBY) scripts/render_index.rb $(DRAFTS) "$(INDEX_ARTIFACT)"

render-problems:
	$(RUBY) scripts/publish_support_artifacts.rb problems

render-schemas:
	$(RUBY) scripts/publish_support_artifacts.rb conformance
	$(RUBY) scripts/publish_support_artifacts.rb schemas

render-support:
	$(RUBY) scripts/publish_support_artifacts.rb

idnits: render-drafts
	@command -v "$(IDNITS)" >/dev/null || { echo "idnits is required"; exit 1; }
	@for draft in $(DRAFTS); do \
		docname=$$(basename "$$draft" .md); \
		echo "== idnits: $$docname.txt =="; \
		$(IDNITS) "$(ARTIFACTS)/$$docname.txt"; \
		echo; \
	done

clean:
	@for draft in $(DRAFTS); do \
		docname=$$(basename "$$draft" .md); \
		rm -f "$(ARTIFACTS)/$$docname.xml"; \
		rm -f "$(ARTIFACTS)/$$docname.txt"; \
		rm -f "$(ARTIFACTS)/$$docname.html"; \
		rm -f "$(ARTIFACTS)/$$docname.pdf"; \
	done
