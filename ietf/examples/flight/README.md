# Flight Itinerary Example

This example shows how ODP can describe a time-sensitive travel Offering without adding
airline-specific fields to the core protocol.

[`flight-offering.json`](./flight-offering.json) illustrates:

- a stable Offering envelope with a human-facing `web_url`; the fixed `get-offering` operation and
  path-safe `id` locate the machine representation;
- nested departure and arrival structures with timezone-aware scheduled times;
- Service-owned carrier, flight, cabin, baggage, and refundability attributes; and
- a `quote` action because availability, traveler-specific fare, taxes, and conditions must be
  obtained from a later operation rather than treated as static discovery data.

[`flight-attributes.schema.json`](./flight-attributes.schema.json) shows how the travel Service
explains those attributes to an unfamiliar agent using JSON Schema types, constraints, titles, and
descriptions. The schema is a descriptive example, not a normative ODP flight vocabulary.
