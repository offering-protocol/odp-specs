# JSON Schemas

This directory contains source JSON Schemas for stable ODP wire objects. Schemas use JSON Schema
Draft 2020-12 and stable `$id` URLs under `https://offeringprotocol.org/schemas/`.

Schemas validate the contract described by normative prose. A schema cannot add a requirement absent
from the specification or relax one the specification requires. Published copies are generated and
checked for drift.

| Schema                                                                                       | Contract                                              |
| -------------------------------------------------------------------------------------------- | ----------------------------------------------------- |
| [`collection.schema.json`](./collection.schema.json)                                         | Full Collection Representation envelope.              |
| [`detail-fields.schema.json`](./detail-fields.schema.json)                                   | Omitted fields available in a Full Representation.    |
| [`local-resource-identifier.schema.json`](./local-resource-identifier.schema.json)           | Service-created Collection and Offering identifiers.  |
| [`local-resource-identifier-list.schema.json`](./local-resource-identifier-list.schema.json) | Unique Service-local resource identifier arrays.      |
| [`protocol-version.schema.json`](./protocol-version.schema.json)                             | Major and minor ODP protocol versions.                |
| [`representation.schema.json`](./representation.schema.json)                                 | Terse and Full Representation selection.              |
| [`resource-identity.schema.json`](./resource-identity.schema.json)                           | Structured identity composed by an Agent.             |
| [`resource-reference.schema.json`](./resource-reference.schema.json)                         | Origin-relative and absolute resource references.     |
| [`service-origin.schema.json`](./service-origin.schema.json)                                 | Canonical Service-origin serialization.               |
| [`service-document.schema.json`](./service-document.schema.json)                             | Well-known Service discovery metadata and operations. |
| [`top-level-document.schema.json`](./top-level-document.schema.json)                         | Shared version-bearing ODP document envelope.         |
