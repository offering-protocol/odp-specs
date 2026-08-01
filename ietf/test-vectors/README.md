# Test Vectors

This directory contains language-neutral positive and negative ODP conformance cases. Each vector
identifies the governing draft, capability profile, participating roles, input, and expected
outcome.

Vectors cover success, malformed input, unsafe links, caching, pagination, filters, search,
extensions, access composition, and compatibility. Implementations publish the profiles and vectors
they pass.

| Area                          | Coverage                                                                                          |
| ----------------------------- | ------------------------------------------------------------------------------------------------- |
| [`identity`](./identity/)     | Service origins, local identifiers, structured identity comparison, and resource references.      |
| [`versioning`](./versioning/) | Protocol versions, top-level placement, media negotiation, compatibility, and Extension handling. |
