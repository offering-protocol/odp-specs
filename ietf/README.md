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

Run `make -C ietf render-support` to publish schemas, descriptive examples, Problem Type pages, and
test vectors into `docs/`. The full check rejects missing, unexpected, or stale published support
artifacts and rejects disagreement between Problem Details vectors and the normative problem-code
table.

Install the pinned Internet-Draft toolchain:

```sh
cd ietf
bundle install
python3 -m venv .venv
.venv/bin/python -m pip install --upgrade pip
.venv/bin/python -m pip install -r requirements.txt
```

Run `make -C ietf render` from the repository root to generate XML, text, HTML, and PDF draft files
under ignored `artifacts/` and regenerate every committed site artifact under `docs/`. Run `make -C
ietf idnits` to render the draft and inspect its text artifact with idnits. The full check also
rejects hard-coded section numbers into external Internet-Drafts and a stale site index.

Rendering derives RFC bibliography dependencies from draft frontmatter and seeds the ignored local
cache from the official `ietf-tools/bibxml-data-archive` before invoking kramdown-rfc. The source
draft remains the reference manifest; no separate RFC list is maintained.

The manual interoperability workflow runs every official Agent SDK against every official Service
SDK and publishes JSON and Markdown matrix artifacts. It is intentionally excluded from pull request
and merge checks. With prepared SDK repositories beside `odp-specs`, run it locally with `make -C
ietf interoperability`; `ODP_NODE_DIR`, `ODP_GO_DIR`, `ODP_JAVA_DIR`, `ODP_PYTHON_DIR`, and
`ODP_RUST_DIR` can select other checkouts.

Normative Internet-Draft prose is authoritative. Supporting artifacts make the contract testable but
do not override the drafts.

Use `guides/internet-draft-revision-guide.md` when advancing the ODP Internet-Draft for IETF
publication. The guide covers revision metadata, repository-wide references, generated artifacts,
submission ordering, and immutable publication records.
