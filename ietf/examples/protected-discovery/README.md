# Protected Discovery

[`protected-service.json`](./protected-service.json) advertises Service-wide AEP onboarding and a
preference for MPP over x402 payment. The advertisement is intentionally not an access policy: it
does not assign protocols to ODP operations or tell an agent to authenticate or pay.

For any operation, the anonymous or current-context request determines the next step:

```http
HTTP/1.1 401 Unauthorized
WWW-Authenticate: AEP service_did="did:web:catalog.example", inspect="https://catalog.example/.well-known/aep"
```

```http
HTTP/1.1 402 Payment Required
WWW-Authenticate: Payment realm="catalog.example", id="challenge-1", method="inflow"
PAYMENT-REQUIRED: <x402 payment requirements>
```

A successful response requires no speculative enrollment or payment even though the Service
advertises support. Conversely, a valid live challenge remains authoritative when cached metadata
omits or disagrees with the challenged protocol. Exact AEP-first retry sequencing is specified
separately from this support summary.
