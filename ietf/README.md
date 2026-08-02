# ODP IETF Workspace

This directory is the source workspace for ODP Internet-Drafts and their implementation-support
artifacts.

| Directory       | Purpose                                                                     |
| --------------- | --------------------------------------------------------------------------- |
| `conformance/`  | Role baselines, generated evidence, and the language-neutral harness.       |
| `examples/`     | Reviewed, non-normative examples that explain complete discovery scenarios. |
| `fixtures/`     | Generated scale profiles and reproducible performance checks.               |
| `guides/`       | Non-normative implementer and author guidance.                              |
| `schemas/`      | Source JSON Schemas for stable wire objects.                                |
| `scripts/`      | Validation, formatting, rendering, and publication tooling.                 |
| `specs/`        | Normative Internet-Draft Markdown source.                                   |
| `templates/`    | Internet-Draft source templates.                                            |
| `test-vectors/` | Positive and negative conformance cases.                                    |

Run `make -C ietf format` to align Markdown tables and wrap prose to 100 columns. Run `make -C ietf
check` to validate formatting, JSON, and example invariants. Rendering and publication targets use
`artifacts/` for generated drafts and `docs/` for the published website. Generated outputs must be
reproducible from this source tree.

Run `make -C ietf render-support` to publish schemas, descriptive examples, and Problem Type pages
into `docs/`. The full check rejects missing, unexpected, or stale published support artifacts and
rejects disagreement between Problem Details vectors and the normative problem-code table.

Normative Internet-Draft prose is authoritative. Supporting artifacts make the contract testable but
do not override the drafts.
