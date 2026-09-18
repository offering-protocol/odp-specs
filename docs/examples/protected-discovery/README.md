# Protected Discovery

[`protected-service.json`](./protected-service.json) advertises AEP enrollment, authentication
before each ODP operation, and authentication before either supported payment rail. Its payment
descriptor order expresses a preference for MPP over x402. The optional payment-option labels
summarize that this Service accepts InFlow and Tempo through MPP and Base through x402. Live
challenges provide the exact protocol-specific payment terms.

The Agent begins with the requested ODP operation. It does not enroll or pay solely because the
Service Document advertises those protocols:

```http
GET /odp/offerings HTTP/1.1
Host: catalog.example

HTTP/1.1 401 Unauthorized
WWW-Authenticate: AEP service_did="did:web:catalog.example", inspect="https://catalog.example/.well-known/aep"
```

This example assumes the AEP Inspect document advertises `aep-jwt` for protected-resource
authentication. A Service advertising a session credential method uses that method's credential
presentation instead.

## MPP branch

After completing AEP, the Agent retries with the dedicated AEP carrier so the standard
`Authorization` field remains available for the MPP payment credential. The authenticated request
can then receive a complete MPP challenge:

```http
GET /odp/offerings HTTP/1.1
Host: catalog.example
AEP-Authorization: AEP <client-assertion>

HTTP/1.1 402 Payment Required
Cache-Control: no-store
WWW-Authenticate: Payment id="qB3wErTyU7iOpAsD9fGhJk", realm="catalog.example", method="inflow", intent="charge", request="eyJhbW91bnQiOiIxMC41IiwiY3VycmVuY3kiOiJVU0RDIiwibWV0aG9kRGV0YWlscyI6eyJyYWlsIjoiYmFsYW5jZSJ9LCJyZWNpcGllbnQiOiIxMTExMTExMS0xMTExLTExMTEtMTExMS0xMTExMTExMTExMTEifQ"
```

The payment-bearing retry uses a newly generated AEP JWT assertion with a fresh `jti`, bound to the
protected-resource request:

```http
GET /odp/offerings HTTP/1.1
Host: catalog.example
AEP-Authorization: AEP <new-client-assertion>
Authorization: Payment <payment-credential>

HTTP/1.1 200 OK
Cache-Control: private
Payment-Receipt: <MPP payment receipt>
Content-Type: application/odp+json
```

## x402 branch

For x402, the authenticated request receives encoded payment requirements in `PAYMENT-REQUIRED`:

```http
GET /odp/offerings HTTP/1.1
Host: catalog.example
AEP-Authorization: AEP <client-assertion>

HTTP/1.1 402 Payment Required
Cache-Control: no-store
PAYMENT-REQUIRED: <x402 payment requirements>
```

After caller approval, the Agent retries with a new request-bound AEP JWT assertion and the x402
payment proof. The successful response includes the encoded settlement result:

```http
GET /odp/offerings HTTP/1.1
Host: catalog.example
AEP-Authorization: AEP <new-client-assertion>
PAYMENT-SIGNATURE: <x402 payment signature>

HTTP/1.1 200 OK
Cache-Control: private
PAYMENT-RESPONSE: <x402 settlement response>
Content-Type: application/odp+json
```

The exact credential, signature, request-binding, and replay rules belong to AEP and the selected
payment protocol rather than ODP. An Agent never copies an AEP assertion, session credential, or
payment credential to another origin.
