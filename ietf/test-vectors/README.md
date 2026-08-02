# Test Vectors

This directory contains language-neutral positive and negative ODP conformance cases. Each vector
identifies the governing draft, category, participating roles, subject, input, and expected outcome.

Vectors cover success, malformed input, unsafe references, caching, pagination, filters, search,
access composition, and compatibility. Generated conformance reports identify the categories and
vectors executed for one role and ODP version.

[`index.json`](./index.json) is the complete, ordered vector entry point and follows
[`../conformance/vector-index.schema.json`](../conformance/vector-index.schema.json). The harness
rejects missing, unindexed, duplicate, or unsorted paths. It derives the report's `vector_revision`
as a SHA-256 digest of the index version, ordered paths, and parsed vector contents, so every report
identifies the exact input set without a separately maintained release number.

Each vector has these common fields:

| Field        | Meaning                                                                |
| ------------ | ---------------------------------------------------------------------- |
| `id`         | Stable identifier unique within the indexed vector set.                |
| `title`      | Human-readable vector title.                                           |
| `drafts`     | Specifications governing the cases.                                    |
| `category`   | Selectable suite and report category.                                  |
| `applies_to` | Roles that can execute the vector.                                     |
| `subject`    | Behavior under test.                                                   |
| `cases`      | Ordered language-neutral inputs and expected outcomes for the subject. |

The adapter stream and generated-report contracts are documented in
[`../conformance`](../conformance/).

| Area                                        | Coverage                                                                                     |
| ------------------------------------------- | -------------------------------------------------------------------------------------------- |
| [`actions`](./actions/)                     | Identity, relations, direct/OpenAPI targets, and narrow failures.                            |
| [`attribute-schemas`](./attribute-schemas/) | Reference, retrieval, dialect, validation, and narrow failure behavior.                      |
| [`collections`](./collections/)             | Directed-acyclic hierarchy, direct membership, depth, and narrow edge failure.               |
| [`composition`](./composition/)             | Service protocol support and authoritative AEP, MPP, and x402 live signals.                  |
| [`conformance`](./conformance/)             | Required Service and Agent role baselines.                                                   |
| [`errors-limits`](./errors-limits/)         | Problem Details, resource ceilings, narrow failures, and bounded retries.                    |
| [`identity`](./identity/)                   | Service origins, local identifiers, structured identity comparison, and resource references. |
| [`offerings`](./offerings/)                 | Offering envelope, attributes, Price Preview, and action placement.                          |
| [`pagination`](./pagination/)               | Page envelopes, continuation links, limits, ordering, lifetime, and conditional retrieval.   |
| [`refinements`](./refinements/)             | Opt-in filter references, contextual counts, response bounds, and continuation behavior.     |
| [`representation`](./representation/)       | Operation defaults, overrides, and exhaustive Detail Fields.                                 |
| [`security`](./security/)                   | Destination, credential, Action, payment, cache, and SSRF protections.                       |
| [`service-document`](./service-document/)   | Well-known metadata, localization, operation advertisement, and endpoint-base validation.    |
| [`versioning`](./versioning/)               | Protocol versions, top-level placement, media negotiation, and compatibility.                |
