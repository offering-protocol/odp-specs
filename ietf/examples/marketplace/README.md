# Marketplace-Scale Catalog Example

This example tests ODP against a Service with millions of independently managed listings and a
large, contextual filter vocabulary. It intentionally uses a few representative records to explain a
scalable protocol shape rather than filling the repository with hundreds of repetitive filters.

The files illustrate a complete sequence:

1. [`marketplace-service.json`](./marketplace-service.json) is the compact cached Service document.
   It advertises its Collection and Offering operations through a fixed endpoint base.
2. [`home-office-collection.json`](./home-office-collection.json) is a full Collection root
   representation with language metadata, an empty `parent_ids` list, and a browser link. Instead of
   embedding every Collection-specific filter, it links to a pageable filter resource.
3. [`home-office-collection-search-response.json`](./home-office-collection-search-response.json)
   shows the same Collection as a terse search item with its root relationship and exhaustive
   `detail_fields`.
4. [`home-office-filters-page-1.json`](./home-office-filters-page-1.json) and
   [`home-office-filters-page-2.json`](./home-office-filters-page-2.json) show short Service-local
   filter identifiers, types, operators, units, sorting capability, and cursor-style continuation.
5. [`home-office-search-response.json`](./home-office-search-response.json) shows terse Offering
   results with Service-selected attributes, exhaustive `detail_fields`, and dynamic value counts.
   Its refinements reference previously advertised filters; they do not define a third filter
   source.
6. [`walnut-standing-desk-offering.json`](./walnut-standing-desk-offering.json) expands one terse
   result into its full Offering, including direct `collection_ids`, Service-owned attributes, and a
   quote action for current price, tax, shipping/pickup, and availability.
7. [`home-office-furniture-attributes.schema.json`](./home-office-furniture-attributes.schema.json)
   teaches an agent how to interpret the marketplace's listing attributes without making that retail
   model normative to ODP.

Together, the files demonstrate why filters are contextual, why the well-known document must remain
bounded, and why directory Service search must not be confused with cross-Service Offering indexing.
