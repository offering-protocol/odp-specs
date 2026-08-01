# Marketplace-Scale Catalog Example

This example tests ODP against a Service with millions of independently managed listings and a
large, contextual filter vocabulary. It intentionally uses a few representative records to explain a
scalable protocol shape rather than filling the repository with hundreds of repetitive filters.

The files illustrate a complete sequence:

1. [`marketplace-service.json`](./marketplace-service.json) is the compact cached Service document.
   It advertises Collection and Offering operations and embeds only a genuinely Service-wide `price`
   filter.
2. [`home-office-collection.json`](./home-office-collection.json) is a full Collection
   representation with machine and browser links. Instead of embedding every Collection-specific
   filter, it links to a pageable filter resource.
3. [`home-office-filters-page-1.json`](./home-office-filters-page-1.json) and
   [`home-office-filters-page-2.json`](./home-office-filters-page-2.json) show short Service-local
   filter identifiers, types, operators, units, sorting capability, and cursor-style continuation.
4. [`home-office-search-response.json`](./home-office-search-response.json) shows terse Offering
   results and dynamic value counts. Its refinements reference previously advertised filters; they
   do not define a third filter source.
5. [`walnut-standing-desk-offering.json`](./walnut-standing-desk-offering.json) expands one terse
   result into its full Offering, including Service-owned attributes and a quote action for current
   price, tax, shipping/pickup, and availability.
6. [`home-office-furniture-attributes.schema.json`](./home-office-furniture-attributes.schema.json)
   teaches an agent how to interpret the marketplace's listing attributes without making that retail
   model normative to ODP.

Together, the files demonstrate why filters are contextual, why the well-known document must remain
bounded, and why directory Service search must not be confused with cross-Service Offering indexing.
