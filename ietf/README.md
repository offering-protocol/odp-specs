# ODP IETF Workspace

This directory is the source workspace for ODP Internet-Drafts and their implementation-support
artifacts.

| Directory       | Purpose                                                                     |
| --------------- | --------------------------------------------------------------------------- |
| `conformance/`  | Profiles, capability manifests, and the language-neutral harness contract.  |
| `examples/`     | Reviewed, non-normative examples that explain complete discovery scenarios. |
| `fixtures/`     | Generated scale profiles and reproducible performance checks.               |
| `guides/`       | Non-normative implementer and author guidance.                              |
| `schemas/`      | Source JSON Schemas for stable wire objects.                                |
| `scripts/`      | Validation, formatting, rendering, and publication tooling.                 |
| `specs/`        | Normative Internet-Draft Markdown sources organized by document family.     |
| `templates/`    | Internet-Draft source templates.                                            |
| `test-vectors/` | Positive and negative conformance cases.                                    |

Run `make -C ietf format` to align Markdown tables and wrap prose to 100 columns. Run `make -C ietf
check` to validate formatting, JSON, and example invariants. Rendering and publication targets use
`artifacts/` for generated drafts and `docs/` for the published website. Generated outputs must be
reproducible from this source tree.

Normative Internet-Draft prose is authoritative. Supporting artifacts make the contract testable but
do not override the drafts.
