# JSON Schemas

This directory contains source JSON Schemas for stable ODP wire objects. Schemas use JSON Schema
Draft 2020-12 and stable `$id` URLs under `https://offeringprotocol.org/schemas/`.

Schemas validate the contract described by normative prose. A schema cannot add a requirement absent
from the specification or relax one the specification requires. Published copies are generated and
checked for drift.

Run `make -C ietf render-schemas` from the repository root to regenerate `docs/schemas/`. The full
repository check rejects a missing schema, an unexpected published file, a byte difference, a
missing title, or a `$id` that does not equal its canonical published URL.

| Schema                                                                                       | Contract                                              |
| -------------------------------------------------------------------------------------------- | ----------------------------------------------------- |
| [`action-relation.schema.json`](./action-relation.schema.json)                               | Action semantic relation identifier.                  |
| [`action-request.schema.json`](./action-request.schema.json)                                 | Compact Action request-body description.              |
| [`action.schema.json`](./action.schema.json)                                                 | Offering Action and exclusive target union.           |
| [`authentication-requirement.schema.json`](./authentication-requirement.schema.json)         | Authentication requirement for an operation.          |
| [`attribute-schema-reference.schema.json`](./attribute-schema-reference.schema.json)         | Reference to a Service-defined Attribute Schema.      |
| [`capability-identifier.schema.json`](./capability-identifier.schema.json)                   | Service-local filter and sort identifiers.            |
| [`capability-link.schema.json`](./capability-link.schema.json)                               | Link to a pageable capability source.                 |
| [`collection-search-request.schema.json`](./collection-search-request.schema.json)           | Collection text and direct-parent search request.     |
| [`collection.schema.json`](./collection.schema.json)                                         | Full Collection Representation envelope.              |
| [`detail-fields.schema.json`](./detail-fields.schema.json)                                   | Omitted fields available in a Full Representation.    |
| [`enrollment-protocol.schema.json`](./enrollment-protocol.schema.json)                       | Service enrollment protocol descriptor.               |
| [`filter-capability-source.schema.json`](./filter-capability-source.schema.json)             | Inline or linked Filter Definition source.            |
| [`filter-definition-page.schema.json`](./filter-definition-page.schema.json)                 | Pageable Filter Definition sequence.                  |
| [`filter-definition.schema.json`](./filter-definition.schema.json)                           | Search Filter Definition.                             |
| [`filter-expression.schema.json`](./filter-expression.schema.json)                           | Filter request expression.                            |
| [`filter-operator.schema.json`](./filter-operator.schema.json)                               | Core filter operators.                                |
| [`filter-type.schema.json`](./filter-type.schema.json)                                       | Core filter value types.                              |
| [`filter-unit.schema.json`](./filter-unit.schema.json)                                       | UCUM and Service-defined units.                       |
| [`http-action-target.schema.json`](./http-action-target.schema.json)                         | Compact GET or POST Action target.                    |
| [`invalid-parameter.schema.json`](./invalid-parameter.schema.json)                           | Structured invalid request parameter.                 |
| [`local-resource-identifier.schema.json`](./local-resource-identifier.schema.json)           | Service-created Collection and Offering identifiers.  |
| [`local-resource-identifier-list.schema.json`](./local-resource-identifier-list.schema.json) | Unique Service-local resource identifier arrays.      |
| [`mcp-endpoint.schema.json`](./mcp-endpoint.schema.json)                                     | Remote MCP Streamable HTTP endpoint descriptor.       |
| [`offering-search-request.schema.json`](./offering-search-request.schema.json)               | Offering text and Collection-scope search request.    |
| [`offering-search-response.schema.json`](./offering-search-response.schema.json)             | Offering search results and requested refinements.    |
| [`offering.schema.json`](./offering.schema.json)                                             | Full Offering Representation envelope.                |
| [`openapi-action-target.schema.json`](./openapi-action-target.schema.json)                   | Exact OpenAPI 3.1 operation reference.                |
| [`operation-descriptor.schema.json`](./operation-descriptor.schema.json)                     | ODP operation and authentication policy.              |
| [`page-envelope.schema.json`](./page-envelope.schema.json)                                   | Shared list and search response envelope.             |
| [`page-limit.schema.json`](./page-limit.schema.json)                                         | Requested maximum items per page.                     |
| [`payment-protocol.schema.json`](./payment-protocol.schema.json)                             | Payment rail and authentication prerequisite.         |
| [`payment-option.schema.json`](./payment-option.schema.json)                                 | Human-consumable payment compatibility label.         |
| [`price-preview.schema.json`](./price-preview.schema.json)                                   | Discovery-time Offering price summary.                |
| [`problem-code.schema.json`](./problem-code.schema.json)                                     | Stable machine-readable problem identifier.           |
| [`problem-details.schema.json`](./problem-details.schema.json)                               | ODP RFC 9457 error response.                          |
| [`protocol-version.schema.json`](./protocol-version.schema.json)                             | Major and minor ODP protocol versions.                |
| [`representation.schema.json`](./representation.schema.json)                                 | Terse and Full Representation selection.              |
| [`refinement-bucket.schema.json`](./refinement-bucket.schema.json)                           | Typed value and contextual match count.               |
| [`refinement-group.schema.json`](./refinement-group.schema.json)                             | Refinement buckets for one advertised filter.         |
| [`resource-identity.schema.json`](./resource-identity.schema.json)                           | Structured identity composed by an Agent.             |
| [`resource-reference.schema.json`](./resource-reference.schema.json)                         | Origin-relative and absolute resource references.     |
| [`schema-reference.schema.json`](./schema-reference.schema.json)                             | Reusable JSON Schema reference.                       |
| [`search-capabilities.schema.json`](./search-capabilities.schema.json)                       | Search capability advertisement container.            |
| [`service-branding-image.schema.json`](./service-branding-image.schema.json)                 | Service branding image reference.                     |
| [`service-branding.schema.json`](./service-branding.schema.json)                             | Square and wide Service branding.                     |
| [`service-document.schema.json`](./service-document.schema.json)                             | Well-known Service discovery metadata and operations. |
| [`service-openapi.schema.json`](./service-openapi.schema.json)                               | Reusable Service OpenAPI reference.                   |
| [`service-origin.schema.json`](./service-origin.schema.json)                                 | Canonical Service-origin serialization.               |
| [`service-protocols.schema.json`](./service-protocols.schema.json)                           | Service-wide enrollment, payment, and trust support.  |
| [`sort-capability-source.schema.json`](./sort-capability-source.schema.json)                 | Inline or linked Sort Definition source.              |
| [`sort-definition-page.schema.json`](./sort-definition-page.schema.json)                     | Pageable Sort Definition sequence.                    |
| [`sort-definition.schema.json`](./sort-definition.schema.json)                               | Advertised indexed sorting recipe.                    |
| [`sort-key.schema.json`](./sort-key.schema.json)                                             | One fixed key in a sorting recipe.                    |
| [`top-level-document.schema.json`](./top-level-document.schema.json)                         | Shared version-bearing ODP document envelope.         |
