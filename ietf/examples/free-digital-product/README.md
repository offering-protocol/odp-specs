# Free Digital Product Example

This example demonstrates that an Offering can be useful without enrollment, payment, checkout, or
physical fulfillment.

[`free-digital-product-offering.json`](./free-digital-product-offering.json) illustrates:

- a public downloadable handbook with machine and browser links;
- multiple file representations, media types, exact byte sizes, and integrity digests;
- Service-owned version, license, language, and file metadata; and
- a public `download` action that requires neither AEP nor a payment protocol.

[`digital-product-attributes.schema.json`](./digital-product-attributes.schema.json) explains the
attributes shape to an agent. The example keeps digital-delivery behavior outside ODP: discovery
describes the files and links to the download operation, while the operation itself performs
delivery.
