# Descriptive ODP examples

These examples explore the ODP information model. They are non-normative design inputs, not a stable
wire contract or industry vocabulary.

## What the examples demonstrate

Each Offering uses a compact protocol envelope and a Service-defined `attributes` object.
`schema.url` identifies a JSON Schema Draft 2020-12 document that lets an agent interpret unfamiliar
structured data through types, constraints, titles, descriptions, and examples. The Service owns
those property names and definitions.

Each Collection and Offering uses a Service-created local `id`. An Agent combines that value with
the Service origin and resource type; the URL is not the resource identity. Same-origin `href` and
`web_url` values use origin-relative absolute paths. `actions` links to subsequent operations
without making enrollment, payment, checkout, or fulfillment part of ODP.

Schema annotations such as `x-odp-unit` and `x-odp-comparison` are exploratory presentation and
comparison hints. They do not identify protocol-owned compute, flight, retail, or digital terms.

## Example sets

- [`flight`](flight/) models nested temporal data and a quote operation whose availability and total
  price may vary.
- [`free-digital-product`](free-digital-product/) models a public, zero-price download with multiple
  file formats.
- [`gpu-rental`](gpu-rental/) models metered capacity and a protected quote operation composed with
  AEP and payment.
- [`marketplace`](marketplace/) models a large catalog with Collections, terse Offering results, and
  linked pageable Collection filters. A compact two-page sample represents the protocol shape; it
  does not attempt to store hundreds of repetitive filters in this repository.

The examples intentionally span different domains to test protocol flexibility. They do not
establish normative ODP profiles for those domains.
