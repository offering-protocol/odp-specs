# GPU Rental Example

This example shows a metered online Service whose capacity and price must be confirmed before use.

[`gpu-rental-offering.json`](./gpu-rental-offering.json) illustrates:

- structured accelerator manufacturer, model, count, memory, region, rental interval, and network
  data;
- explicit units and numeric comparison hints in a Service-owned attributes schema;
- a metered Price Preview for early comparison, without promising final capacity or settlement
  terms; and
- a compact JSON `quote` action whose live AEP, MPP, or x402 challenges remain authoritative.

[`gpu-rental-attributes.schema.json`](./gpu-rental-attributes.schema.json) explains the
compute-specific structure. It does not create a normative ODP compute profile or require other GPU
Services to use the same property names.
