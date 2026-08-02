# Minimum Service Integration

This example shows the complete catalog surface required for ODP Service conformance. It does not
use Collections, search, prices, attributes, schemas, Actions, onboarding, or payments.

[`minimum-service.json`](./minimum-service.json) publishes the public Service Document and
advertises the two required operations. [`offerings-page.json`](./offerings-page.json) is the first
and final `list-offerings` page. [`consultation-offering.json`](./consultation-offering.json) is the
Full Offering returned by `get-offering`.

The corresponding requests are:

```http
GET /.well-known/odp
GET /odp/offerings
GET /odp/offerings/consultation
```

An integration can add optional operations and per-resource features independently. The minimum
integration is the required Service role baseline, not a separately advertised capability or
profile.
