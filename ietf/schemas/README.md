# JSON Schemas

This directory contains source JSON Schemas for stable ODP wire objects. Schemas use JSON Schema
Draft 2020-12 and stable `$id` URLs under `https://offeringprotocol.org/schemas/`.

Schemas validate the contract described by normative prose. A schema cannot add a requirement absent
from the specification or relax one the specification requires. Published copies are generated and
checked for drift.

| Schema                                                                                       | Contract                                              |
| -------------------------------------------------------------------------------------------- | ----------------------------------------------------- |
| [`attribute-schema-reference.schema.json`](./attribute-schema-reference.schema.json)         | Reference to a Service-defined Attribute Schema.      |
| [`capability-identifier.schema.json`](./capability-identifier.schema.json)                   | Service-local filter and sort identifiers.            |
| [`collection-search-request.schema.json`](./collection-search-request.schema.json)           | Collection text and direct-parent search request.     |
| [`collection.schema.json`](./collection.schema.json)                                         | Full Collection Representation envelope.              |
| [`detail-fields.schema.json`](./detail-fields.schema.json)                                   | Omitted fields available in a Full Representation.    |
| [`filter-definition.schema.json`](./filter-definition.schema.json)                           | Search Filter Definition.                             |
| [`filter-expression.schema.json`](./filter-expression.schema.json)                           | Filter request expression.                            |
| [`filter-operator.schema.json`](./filter-operator.schema.json)                               | Core filter operators.                                |
| [`filter-type.schema.json`](./filter-type.schema.json)                                       | Core filter value types.                              |
| [`filter-unit.schema.json`](./filter-unit.schema.json)                                       | UCUM and Service-defined units.                       |
| [`invalid-parameter.schema.json`](./invalid-parameter.schema.json)                           | Structured invalid request parameter.                 |
| [`local-resource-identifier.schema.json`](./local-resource-identifier.schema.json)           | Service-created Collection and Offering identifiers.  |
| [`local-resource-identifier-list.schema.json`](./local-resource-identifier-list.schema.json) | Unique Service-local resource identifier arrays.      |
| [`offering-search-request.schema.json`](./offering-search-request.schema.json)               | Offering text and Collection-scope search request.    |
| [`offering.schema.json`](./offering.schema.json)                                             | Full Offering Representation envelope.                |
| [`page-envelope.schema.json`](./page-envelope.schema.json)                                   | Shared list and search response envelope.             |
| [`page-limit.schema.json`](./page-limit.schema.json)                                         | Requested maximum items per page.                     |
| [`price-preview.schema.json`](./price-preview.schema.json)                                   | Discovery-time Offering price summary.                |
| [`problem-code.schema.json`](./problem-code.schema.json)                                     | Stable machine-readable problem identifier.           |
| [`problem-details.schema.json`](./problem-details.schema.json)                               | ODP RFC 9457 error response.                          |
| [`protocol-version.schema.json`](./protocol-version.schema.json)                             | Major and minor ODP protocol versions.                |
| [`representation.schema.json`](./representation.schema.json)                                 | Terse and Full Representation selection.              |
| [`resource-identity.schema.json`](./resource-identity.schema.json)                           | Structured identity composed by an Agent.             |
| [`resource-reference.schema.json`](./resource-reference.schema.json)                         | Origin-relative and absolute resource references.     |
| [`service-origin.schema.json`](./service-origin.schema.json)                                 | Canonical Service-origin serialization.               |
| [`sort-definition.schema.json`](./sort-definition.schema.json)                               | Advertised indexed sorting recipe.                    |
| [`sort-key.schema.json`](./sort-key.schema.json)                                             | One fixed key in a sorting recipe.                    |
| [`service-document.schema.json`](./service-document.schema.json)                             | Well-known Service discovery metadata and operations. |
| [`top-level-document.schema.json`](./top-level-document.schema.json)                         | Shared version-bearing ODP document envelope.         |
