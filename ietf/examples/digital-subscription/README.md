# Digital Subscription Example

This example shows how a software Service can make a recurring plan discoverable while leaving
account creation, billing, payment, renewal, cancellation, and entitlement enforcement to the
systems that own those operations.

[`team-annual-offering.json`](./team-annual-offering.json) represents one independently actionable
annual plan. The fixed Price Preview is the advertised price for the term described by the
Service-owned `billing_term` attribute. It is not a payment instruction, an invoice, or a promise
that tax and buyer-specific adjustments are already included.

The quote action lets the Service collect parameters such as seat count and billing location before
returning current commercial terms. The subsequent subscription flow may compose with AEP, MPP, or
x402, but those protocols remain independent from ODP.

[`digital-subscription-attributes.schema.json`](./digital-subscription-attributes.schema.json)
teaches an agent how to interpret this Service's plan:

- `billing_term` uses an ISO 8601 duration for the period covered by the previewed amount;
- `renews_automatically` and `cancellation_timing` describe the renewal policy;
- `seat_limits` defines valid account sizes; and
- `features` describes plan entitlements without creating a universal ODP feature vocabulary.

The schema is descriptive and non-normative. Services remain free to model subscriptions with
different fields and structures.
