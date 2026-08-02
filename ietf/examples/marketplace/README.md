# Marketplace-Scale Catalog Example

This example tests ODP against a Service with millions of independently managed listings and a
large, contextual filter vocabulary. It intentionally uses a few representative records to explain a
scalable protocol shape rather than filling the repository with hundreds of repetitive filters.

The files illustrate a complete sequence:

1. [`marketplace-service.json`](./marketplace-service.json) is the compact cached Service document.
   It advertises its Collection and Offering operations through a fixed endpoint base. Its localized
   freeform keywords help a directory index the Service but do not advertise catalog query terms,
   filters, suggestions, or facets. Its protocol summary advertises Service-wide AEP, MPP, and x402
   support without claiming that any particular catalog request requires them.
2. [`home-office-collection.json`](./home-office-collection.json) is a full Collection root
   representation with language metadata, omitted root `parent_ids`, and a browser link. Instead of
   embedding every Collection-specific filter, it links to a pageable filter resource while
   embedding one supported indexed sort recipe.
3. [`home-office-collection-search-request.json`](./home-office-collection-search-request.json)
   combines a Service-interpreted text query with the exact root-Collection constraint.
4. [`home-office-collection-search-response.json`](./home-office-collection-search-response.json)
   shows the same Collection as a terse search item with its root relationship and exhaustive
   `detail_fields`. The Service owns matching and ordering.
5. [`home-office-filters-page-1.json`](./home-office-filters-page-1.json) and
   [`home-office-filters-page-2.json`](./home-office-filters-page-2.json) show short Service-local
   filter identifiers, types, operators, units, and cursor-style continuation.
6. [`home-office-offering-search-request.json`](./home-office-offering-search-request.json) combines
   a Service-interpreted text query with explicit descendant expansion below the selected
   Collection, indexed filtering and sorting, and an explicit request for two advertised
   refinements.
7. [`home-office-search-response.json`](./home-office-search-response.json) shows terse Offering
   results with Service-selected ordering and attributes, exhaustive `detail_fields`, and requested
   contextual value counts. Its refinements reference previously advertised refinable filters; they
   do not define a third filter source. Exact and lower-bound counts demonstrate how a marketplace
   can expose useful navigation without requiring expensive exact aggregation for every bucket.
8. [`walnut-standing-desk-offering.json`](./walnut-standing-desk-offering.json) expands one terse
   result into its full Offering, including direct `collection_ids`, a `starting_at` Price Preview,
   Service-owned attributes, and a quote action for current tax, shipping/pickup, and availability.
9. [`home-office-furniture-attributes.schema.json`](./home-office-furniture-attributes.schema.json)
   teaches an agent how to interpret the marketplace's listing attributes without making that retail
   model normative to ODP.

Together, the files demonstrate why filters are contextual, why the well-known document must remain
bounded, and why directory Service search must not be confused with cross-Service Offering indexing.
