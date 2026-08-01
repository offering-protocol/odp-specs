# GPU Rental Example

This example shows a metered online Service whose capacity and price must be confirmed before use.

[`gpu-rental-offering.json`](./gpu-rental-offering.json) illustrates:

- structured accelerator manufacturer, model, count, memory, region, rental interval, and network
  data;
- explicit units and numeric comparison hints in a Service-owned attributes schema;
- a quote action rather than a static promise of capacity or final price; and
- advisory access sequencing in which AEP enrollment happens before either MPP or x402 payment,
  while live HTTP challenges remain authoritative.

[`gpu-rental-attributes.schema.json`](./gpu-rental-attributes.schema.json) explains the
compute-specific structure. It does not create a normative ODP compute profile or require other GPU
Services to use the same property names.
