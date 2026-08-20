# Physical Retail Example

This example shows how a retailer can describe a physical good without turning ODP into an order,
tax, inventory, or fulfillment protocol.

[`travel-mug-offering.json`](./travel-mug-offering.json) represents one independently actionable
variant: a 20-ounce blue travel mug. Its Service-local `id` belongs to that exact variant, so an
agent does not need a second protocol-specific option-selection step before requesting a quote.
Other colors or sizes would be separate Offerings when they can be purchased independently.

The ordered `images` array gives agents a primary product image with alternative text, intrinsic
dimensions, and an optional media-type hint without requiring interpretation of the retailer's
attribute schema.

The Price Preview is the advertised item price. The quote action determines current tax, shipping,
pickup, inventory, and final price for the buyer's circumstances. ODP does not calculate or settle
those values.

[`physical-retail-attributes.schema.json`](./physical-retail-attributes.schema.json) explains the
Service-owned attributes:

- `sku`, `brand`, `color`, and `capacity_ml` distinguish and compare the variant;
- `tax_classification` is the retailer's input to its own tax process, not an ODP tax rule;
- `inventory` reports a regional snapshot and the time at which it was observed; and
- `fulfillment` advertises whether shipping and pickup may be requested, without promising that a
  particular address or store can fulfill the order.

The schema is descriptive and non-normative. Another retailer can use a different attribute model
and publish its own JSON Schema.
