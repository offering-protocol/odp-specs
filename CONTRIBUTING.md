# Contributing

This repository contains Internet-Draft sources and the schemas, examples, test vectors, conformance
material, and publication tooling that support the Offering Discovery Protocol (ODP).

## Making Changes

- `main` is the protected stable branch.
- Use a focused feature branch and pull request for each protocol concern.
- Open an issue or discussion before changing a public wire shape, protocol boundary, or conformance
  rule.
- Describe the concrete agent and Service interaction, alternatives, compatibility impact,
  security/privacy impact, and executable evidence.

## Pull Request Checklist

1. Run `make -C ietf check`.
2. Render affected specification and web artifacts with the targets documented in `ietf/README.md`.
3. Update normative prose, schemas, examples, vectors, conformance profiles, registries, and guides
   together when the observable contract changes.
4. Confirm links use stable targets and generated artifacts reproduce cleanly.
5. Confirm public files contain no internal roadmap, private partner context, or speculative launch
   language.
6. Disclose significant artificial-intelligence assistance in the pull request and review generated
   text for protocol accuracy, source attribution, and repository hygiene.

## Evidence Requirements

Normative behavior requires implementation evidence in the Node.js reference implementation and
conformance evidence from an independent implementation before it is declared stable. Domain
examples should exercise general ODP behavior without making an industry-specific vocabulary
normative.

## Publishing an Internet-Draft Revision

After an Internet-Draft revision is submitted and its repository commit is verified:

1. Render the draft and run idnits with `make -C ietf idnits`.
2. Create an annotated Git tag matching the full document name.
3. Create a GitHub Release with the same name and attach that draft's HTML, PDF, text, and XML
   artifacts.

Published revision tags and releases are immutable. Corrections use the next Internet-Draft revision
rather than moving or replacing a published tag.

## Writing and Data Conventions

- Follow `ietf/STYLE.md` for Internet-Draft conventions.
- Use RFC 2119 and RFC 8174 keywords only in normative specification text.
- Use fictional but realistic domains and data in examples.
- Use `lower_snake_case` JSON field names and two-space JSON indentation.
- Keep public documentation focused on the current protocol contract.

## Licensing

By contributing, you agree that specification materials are dedicated under CC0 1.0 and repository
tooling is available under Apache License 2.0 OR MIT as described in [LICENSE.md](./LICENSE.md).
IETF contributions are also subject to the policies identified there.
