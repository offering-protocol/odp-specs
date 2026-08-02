# Test Vectors

This directory contains language-neutral positive and negative ODP conformance cases. Each vector
identifies the governing draft, capability profile, participating roles, input, and expected
outcome.

Vectors cover success, malformed input, unsafe references, caching, pagination, filters, search,
access composition, and compatibility. Implementations publish the profiles and vectors they pass.

| Area                                      | Coverage                                                                                     |
| ----------------------------------------- | -------------------------------------------------------------------------------------------- |
| [`collections`](./collections/)           | Directed-acyclic hierarchy, direct membership, depth, and narrow edge failure.               |
| [`identity`](./identity/)                 | Service origins, local identifiers, structured identity comparison, and resource references. |
| [`representation`](./representation/)     | Operation defaults, overrides, and exhaustive Detail Fields.                                 |
| [`service-document`](./service-document/) | Well-known metadata, localization, operation advertisement, and endpoint-base validation.    |
| [`versioning`](./versioning/)             | Protocol versions, top-level placement, media negotiation, and compatibility.                |
