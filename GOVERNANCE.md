# ODP Specification Governance

This document defines how the ODP specification set evolves. It is project governance, not protocol
text. Published Internet-Draft documents are authoritative for protocol requirements.

## Scope

This repository maintains Internet-Draft sources, implementation guides, examples, JSON Schemas,
test vectors, conformance profiles, and the generated specification website.

## Change Classes

| Change class      | Examples                                                                               | Review expectation                                                           |
| ----------------- | -------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| Editorial         | Typographical fixes, clearer prose, repaired links                                     | Normal review; no wire change.                                               |
| Support artifact  | Examples, guides, schemas, vectors, harness checks                                     | Verify alignment with normative prose and run repository checks.             |
| Clarification     | Resolves ambiguous requirements without changing intended behavior                     | Review compatibility and all affected artifacts.                             |
| Protocol behavior | Wire fields, link relations, errors, algorithms, security, or conformance requirements | Design review, compatibility analysis, implementation evidence, and vectors. |

## Authority and Compatibility

Normative Internet-Draft prose takes precedence over schemas, examples, vectors, guides, and
generated pages. A conflict is repaired in every affected artifact. Compatibility is evaluated from
observable wire behavior, not repository file history.

Behavior-changing work identifies affected agents and Services, security/privacy consequences,
versioning impact, migration behavior, and conformance changes. Existing vectors are changed only to
correct an error or accompany an approved compatibility decision.

## Protocol Lifecycle

ODP wire versions use the `MAJOR.MINOR` form defined by the authoritative Internet-Draft. Repository
commits, Git tags, Internet-Draft revisions, implementation versions, and conformance-report formats
are separate identifiers and do not change `odp_version`.

| Change                                            | Protocol-version effect                                                                 |
| ------------------------------------------------- | --------------------------------------------------------------------------------------- |
| Editorial or non-normative support correction     | None.                                                                                   |
| Compatible optional behavior                      | Increment `MINOR` when the behavior becomes normative.                                  |
| Removal, incompatible redefinition, or wire epoch | Increment `MAJOR`; publish new versioned resources rather than changing old identities. |

An Internet-Draft revision such as `-00` or `-01` records an IETF document publication. It is not a
protocol version and does not imply compatibility by itself. Compatibility is determined by the
normative wire rules and `odp_version`.

## Deprecation

A same-major revision may deprecate a field, value, operation, or behavior, but it remains valid for
the rest of that major-version family. Deprecation is recorded in normative prose and migration
guidance; it does not introduce an unadvertised wire signal. Removal or incompatible reuse requires
a new major version.

## Review and Evidence

Protocol changes require focused pull requests and passing repository checks. Normative behavior
requires executable evidence in the Node.js reference implementation and conformance evidence from
an independent implementation before it is declared stable. Security-sensitive changes receive
explicit threat and privacy review.

## Publication

The `ietf/` directory is the source for specifications and support material. The `docs/` directory
is the published site. Rendered Internet-Draft artifacts are reproducible and published as release
assets. Stable JSON Schema URLs and other web artifacts are generated from their source files and
checked for drift.

Every successful deployment replaces the `latest` GitHub Release with rendered artifacts from the
deployed `main` commit. `latest` is a convenience snapshot and is not an immutable specification
version.

An Internet-Draft submitted to the IETF receives an immutable release and Git tag matching its full
document name, for example `draft-kavian-offering-discovery-protocol-00`. An immutable release is
not replaced or retagged. A correction after submission is published as the next Internet-Draft
revision.

Stable support-resource URLs remain available for the compatibility family they identify. A
same-major update may change their content only in ways permitted by the protocol compatibility
rules. An incompatible resource receives a new versioned URL; an existing stable URL is not silently
repurposed.

## IETF Relationship

The IETF process controls standardization of submitted drafts. IETF working-group decisions, IETF
Trust terms, and applicable IETF policies take precedence for the affected document.

## Maintainers and Contact

Repository ownership is declared in [CODEOWNERS](./CODEOWNERS). Technical proposals use GitHub
issues or discussions. Standards and specification questions may be sent to `nas@inflowpay.ai`;
security and conduct reports use the private contacts in [SECURITY.md](./SECURITY.md) and
[CODE_OF_CONDUCT.md](./CODE_OF_CONDUCT.md).
