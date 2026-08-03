# Protected Discovery

[`protected-service.json`](./protected-service.json) advertises AEP enrollment, authentication
before each ODP operation, and authentication before either supported payment rail. Its payment
descriptor order expresses a preference for MPP over x402.

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

A valid live challenge supplies the credentials or payment requirements needed to continue and
remains authoritative when cached metadata disagrees with the response.

When both enrollment authentication and payment protect an operation, the exchanges occur in this
order:

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
