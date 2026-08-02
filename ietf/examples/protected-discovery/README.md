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
omits or disagrees with the challenged protocol.

When both onboarding and payment protect an operation, the exchanges occur in this order:

```http
POST /odp/search-offerings HTTP/1.1
Host: catalog.example

HTTP/1.1 401 Unauthorized
WWW-Authenticate: AEP service_did="did:web:catalog.example", inspect="https://catalog.example/.well-known/aep"
```

After completing AEP, the Agent retries with the dedicated AEP carrier so a later MPP credential can
use `Authorization`:

```http
POST /odp/search-offerings HTTP/1.1
Host: catalog.example
AEP-Authorization: AEP <client-assertion>

HTTP/1.1 402 Payment Required
WWW-Authenticate: Payment realm="catalog.example", id="challenge-1", method="inflow"
```

The payment-bearing retry preserves AEP authentication:

```http
POST /odp/search-offerings HTTP/1.1
Host: catalog.example
AEP-Authorization: AEP <new-client-assertion>
Authorization: Payment <payment-credential>

HTTP/1.1 200 OK
Content-Type: application/odp+json
```

For x402, the final request uses `PAYMENT-SIGNATURE` instead of `Authorization: Payment`. The exact
credential, signature, request-binding, and replay rules belong to AEP and the selected payment
protocol rather than ODP.
