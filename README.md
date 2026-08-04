# Offering Discovery Protocol Specifications

[![CI](https://github.com/offering-protocol/odp-specs/actions/workflows/ci.yml/badge.svg)](https://github.com/offering-protocol/odp-specs/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/License-CC0%20%2B%20Apache--2.0%2FMIT-yellow.svg)](./LICENSE.md)

The open specification for agent-native discovery of Services, Collections, and Offerings.

The Offering Discovery Protocol (ODP) defines how an agent inspects a Service, navigates or searches
its Collections, finds Offerings, interprets Service-defined structured attributes, and discovers
the operation that comes next. ODP is designed for independent implementations and for catalogs
ranging from a handful of Offerings to large marketplaces.

```text
Discover Services        Inspect a Service       Navigate its catalog          Continue
Directory search ──────▶ /.well-known/odp ─────▶ Collections / Offerings ────▶ Linked action
```

## Protocol at a Glance

| Resource or operation | What the agent learns                                                                                                   |
| --------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| Directory search      | Which Services may satisfy the agent's goal, using deterministic search, keywords, facets, suggestions, and pagination. |
| Service document      | Service identity, description, keywords, supported operations, and the HTTP endpoint base.                              |
| Collections           | Navigational groupings, relationships, Offering membership, and contextual filter capabilities.                         |
| Offerings             | Stable descriptive fields, optional browser links, Service-defined structured attributes, and subsequent actions.       |
| Attribute schema      | JSON Schema definitions that explain a Service's domain-specific Offering data.                                         |

Directory discovery and catalog discovery are separate. The canonical directory indexes public
Service metadata; it does not ingest complete Offering catalogs. Agents search for Services and then
query each relevant Service through the operations in its ODP document.

## Extensible Offering Data

ODP defines a stable Offering envelope without defining a universal product taxonomy. A Service
places domain-specific data in `attributes` and publishes a JSON Schema Draft 2020-12 document
describing that structure. Agents can use the schema's types, constraints, titles, descriptions, and
examples to understand unfamiliar data.

Filters use short Service-local identifiers. Small Services can embed filter definitions, while
large Services can link to pageable Collection-scoped filter documents. Dynamic refinements
reference those advertised definitions.

## Protocol Composition

ODP composes with AEP, MPP, and x402. Discovery may be public or protected by enrollment, payment,
or both. Live HTTP authentication and payment challenges are authoritative.

ODP does not define enrollment, payment, checkout, tax calculation, shipping, pickup, fulfillment,
or digital delivery. It describes discoverable resources and links agents to the appropriate
subsequent operation.

## Canonical Directory

Official development kits use:

- `https://directory.offeringprotocol.org` for production; and
- `https://sandbox.offeringprotocol.org` for sandbox testing.

Service owners submit and manage directory listings through `https://directory.inflowpay.ai`. The
directory API is a code-defined product contract rather than part of the IETF ODP specification.

## Implement and Test

This repository connects normative documents to implementation-support artifacts:

| Area                                        | Contents                                                               |
| ------------------------------------------- | ---------------------------------------------------------------------- |
| [`ietf/conformance`](./ietf/conformance/)   | Conformance profiles, capability manifests, and harness documentation. |
| [`ietf/examples`](./ietf/examples/)         | Reviewed protocol examples spanning small Services and marketplaces.   |
| [`ietf/guides`](./ietf/guides/)             | Non-normative implementation and authoring guidance.                   |
| [`ietf/schemas`](./ietf/schemas/)           | JSON Schemas for stable ODP wire objects.                              |
| [`ietf/specs`](./ietf/specs/)               | Internet-Draft Markdown sources.                                       |
| [`ietf/test-vectors`](./ietf/test-vectors/) | Positive and negative conformance inputs and expected outcomes.        |

Internet-Draft prose is normative. Schemas, examples, and test vectors support implementations and
do not replace the specification.

## Read the Specification

| Document                                                                                       | Scope             |
| ---------------------------------------------------------------------------------------------- | ----------------- |
| [The Offering Discovery Protocol](./ietf/specs/draft-kavian-offering-discovery-protocol-00.md) | The ODP protocol. |

## Repository Map

```text
odp-specs/
├── artifacts/          # local rendered drafts; generated and ignored
├── docs/               # published website and generated support artifacts
└── ietf/
    ├── conformance/    # profiles and harness contract
    ├── examples/       # reviewed protocol examples and transcripts
    ├── guides/         # non-normative implementation guidance
    ├── schemas/        # source JSON Schemas
    ├── specs/          # Internet-Draft Markdown sources
    └── test-vectors/   # conformance inputs and expected outcomes
```

## Build and Validate

Install the rendering dependencies once:

```sh
bundle install --gemfile ietf/Gemfile
python3 -m venv ietf/.venv
ietf/.venv/bin/python -m pip install -r ietf/requirements.txt
```

Format the sources, regenerate every committed artifact, and run the complete pull-request gate:

```sh
make -C ietf format
make -C ietf render
make -C ietf check
```

Commit the resulting source and `docs/` changes together. Continuous integration reruns the render
and rejects the pull request when `git diff --exit-code -- docs` finds uncommitted generated drift.

The IETF workspace provides formatting, support-artifact publication, conformance, draft rendering,
idnits, and drift checks as described in [`ietf/README.md`](./ietf/README.md).

Stable support resources are published at:

- `https://offeringprotocol.org/schemas/` for protocol wire schemas;
- `https://offeringprotocol.org/conformance/` for offline harness schemas;
- `https://offeringprotocol.org/examples/` for descriptive examples; and
- `https://offeringprotocol.org/problems/` for Problem Details type documentation.

The specification website is deployed from the committed `docs/` tree to
[`www.offeringprotocol.org`](https://www.offeringprotocol.org/). Pull requests verify generated site
artifacts before the deployment workflow publishes `main`. Rendered HTML, text, XML, and PDF drafts
are available from the [latest GitHub
release](https://github.com/offering-protocol/odp-specs/releases/latest).

Protocol compatibility, deprecation, Internet-Draft revisions, and immutable publication releases
are governed by [GOVERNANCE.md](./GOVERNANCE.md).

## Reference Implementations

Official implementations are maintained by the
[`offering-protocol`](https://github.com/offering-protocol) organization:

- [`odp-go`](https://github.com/offering-protocol/odp-go);
- [`odp-java`](https://github.com/offering-protocol/odp-java);
- [`odp-node`](https://github.com/offering-protocol/odp-node), the reference TypeScript/Node.js
  implementation;
- [`odp-python`](https://github.com/offering-protocol/odp-python); and
- [`odp-rust`](https://github.com/offering-protocol/odp-rust).

## Contributing and Contact

See [CONTRIBUTING.md](./CONTRIBUTING.md) for the contribution workflow and
[GOVERNANCE.md](./GOVERNANCE.md) for specification governance. Technical proposals belong in GitHub
issues or discussions. Standards and specification questions may be sent to `nas@inflowpay.ai`.

Report vulnerabilities through [SECURITY.md](./SECURITY.md) and conduct concerns through
[CODE_OF_CONDUCT.md](./CODE_OF_CONDUCT.md).

## License and Copyright

See [LICENSE.md](./LICENSE.md). Specification materials are dedicated to the public domain under CC0
1.0. Repository tooling is available under Apache License 2.0 OR MIT. The repository-wide tooling
attribution is stated in [COPYRIGHT](./COPYRIGHT) and applies under either license choice.
