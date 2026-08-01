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

## IETF Relationship

The IETF process controls standardization of submitted drafts. IETF working-group decisions, IETF
Trust terms, and applicable IETF policies take precedence for the affected document.

## Maintainers and Contact

Repository ownership is declared in [CODEOWNERS](./CODEOWNERS). Technical proposals use GitHub
issues or discussions. Standards and specification questions may be sent to `nas@inflowpay.ai`;
security and conduct reports use the private contacts in [SECURITY.md](./SECURITY.md) and
[CODE_OF_CONDUCT.md](./CODE_OF_CONDUCT.md).
