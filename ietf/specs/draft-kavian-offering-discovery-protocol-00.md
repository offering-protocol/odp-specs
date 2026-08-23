---
title: The Offering Discovery Protocol
abbrev: ODP
docname: draft-kavian-offering-discovery-protocol-00
date: 2026-08-23
category: std
ipr: trust200902
submissiontype: IETF
stand_alone: true

author:
  -
    ins: N. Kavian
    name: Nas Kavian
    organization: Jarwin, Inc. (InFlow)
    email: nas@inflowpay.ai

normative:
  RFC3986:
  RFC4647:
  RFC5646:
  RFC6454:
  RFC6838:
  RFC6839:
  RFC6890:
  RFC6901:
  RFC8259:
  RFC8615:
  RFC9110:
  RFC9111:
  RFC9457:
    title: Problem Details for HTTP APIs
    target: https://www.rfc-editor.org/info/rfc9457
    date: 2023-07
    seriesinfo:
      RFC: 9457
      DOI: 10.17487/RFC9457
    author:
      - ins: M. Nottingham
      - ins: E. Wilde
      - ins: S. Dalal
  OPENAPI31:
    title: OpenAPI Specification v3.1.2
    target: https://spec.openapis.org/oas/v3.1.2.html
    date: 2025-09-19
    author:
      - org: OpenAPI Initiative
  UCUM:
    title: The Unified Code for Units of Measure
    target: https://ucum.org/ucum
    author:
      -
        org: Regenstrief Institute, Inc.

informative:
  AEP:
    title: "The Agent Enrollment Protocol"
    target: https://datatracker.ietf.org/doc/draft-kavian-agent-enrollment-protocol/
    date: 2026-07-23
    seriesinfo:
      Internet-Draft: draft-kavian-agent-enrollment-protocol-02
    author:
      - ins: N. Kavian
        name: Nas Kavian
  JSON-SCHEMA:
    title: JSON Schema
    target: https://json-schema.org/draft/2020-12/json-schema-core.html
    author:
      -
        ins: A. Wright
      -
        ins: H. Andrews
      -
        ins: B. Hutton
  MCP:
    title: Model Context Protocol
    target: https://modelcontextprotocol.io/specification/2026-07-28
    date: 2026-07-28
    author:
      - org: Model Context Protocol
  MPP:
    title: 'The "Payment" HTTP Authentication Scheme'
    target: https://datatracker.ietf.org/doc/draft-ryan-httpauth-payment/
    date: 2026-03-17
    seriesinfo:
      Internet-Draft: draft-ryan-httpauth-payment-01
    author:
      - ins: B. Ryan
        name: Brendan Ryan
      - ins: J. Moxey
        name: Jake Moxey
      - ins: T. Meagher
        name: Tom Meagher
      - ins: J. Weinstein
        name: Jeff Weinstein
      - ins: S. Kaliski
        name: Steve Kaliski
  X402:
    title: x402 Specification
    target: https://github.com/x402-foundation/x402/tree/main/specs
    author:
      - org: x402 Foundation
...

--- abstract

The Offering Discovery Protocol (ODP) enables an automated Agent to inspect a Service, discover its
Collections and Offerings, interpret Service-defined structured attributes, and identify links to
subsequent operations. ODP supports catalogs ranging from a few Offerings to large marketplaces
without imposing a universal product taxonomy. This document defines the protocol's scope,
terminology, roles, discovery architecture, extensibility model, composition boundaries, and
conformance model.

--- middle

# Introduction

Automated Agents need a deterministic way to learn what a Service offers before selecting an
enrollment, payment, fulfillment, or other downstream protocol. Human-oriented pages and private
catalog interfaces do not provide a common discovery contract. A single rigid product model is also
insufficient for domains as different as flights, downloadable materials, subscriptions, physical
goods, and rented compute capacity.

ODP provides a stable discovery envelope and lets each Service describe domain-specific data with
machine-readable schemas. Discovery begins with the Service document at `/.well-known/odp` and
continues through a fixed set of operations advertised by that document.

ODP representations use JSON as defined by {{RFC8259}} and HTTP semantics as defined by {{RFC9110}}.

A directory can help an Agent locate candidate Services. A directory indexes Service metadata, not
complete Offering catalogs. The Agent queries each candidate Service for authoritative Collection
and Offering data.

# Requirements Language

{::boilerplate bcp14-tagged}

# Scope

ODP defines:

* discovery of a Service's ODP capabilities through a well-known Service document;
* deterministic navigation and search of Collections and Offerings;
* stable descriptive envelopes for Services, Collections, and Offerings;
* Service-defined structured Offering attributes described by JSON Schema;
* discovery of deterministic search terms, filters, and pagination capabilities;
* terse representations for result sets and full representations for inspection;
* optional links from discovery resources to browser experiences and subsequent operations;
* optional discovery of remote Model Context Protocol endpoints; and
* Agent and Service conformance requirements.

ODP is applicable whether access is public or subject to authentication, enrollment, payment, or
another policy enforced by the Service.

# Non-Goals

ODP does not define:

* a universal taxonomy or rigid domain model for products and services;
* a protocol for enrollment, authentication, payment, checkout, tax calculation, shipping, pickup,
  fulfillment, or delivery;
* MCP transport, capability, tool, resource, prompt, version-negotiation, or authorization behavior;
* a requirement to replicate a Service's full catalog into a directory;
* ranking policy, recommendation policy, or natural-language interpretation;
* a directory protocol or a requirement that a directory exist; or
* the business rules that determine whether an Offering can be acquired.

Examples and domain profiles can demonstrate compute, flight, digital, physical, or other data.
Those examples do not add requirements to the ODP core protocol.

# Terminology

Agent
: Software acting for a user or another principal that discovers and evaluates ODP resources.

Service
: An origin that publishes an ODP Service document and exposes one or more ODP capabilities. A
  Service can represent a merchant, marketplace, public organization, software system, or another
  discoverable entity. A Service is not necessarily a seller.

Service Document
: The JSON representation published at `/.well-known/odp`. It describes the Service and advertises
  the ODP operations that the Service exposes.

Collection
: An optional, Service-defined grouping used to navigate or constrain Offerings. Collections can be
  hierarchical, overlapping, or independent and do not impose a universal taxonomy.

Offering
: A discoverable description of something the Service makes available. An Offering can describe a
  free or paid item, a physical or digital good, a scheduled resource, a subscription, a rental, or
  another Service-defined opportunity.

Terse Representation
: A partial Collection or Offering representation used for listing, search, navigation, and
  comparison. It uses the same field names and locations as the Full Representation.

Full Representation
: A resource representation containing the complete ODP description available to the Agent under the
  current access policy.

Detail Fields
: An optional, exhaustive list of fields present in the corresponding Full Representation and
  omitted from a Terse Representation. Entries are JSON Pointers.

Attribute Schema
: A JSON Schema document that describes Service-defined structured data carried by an Offering.

Filter Definition
: Metadata that describes a deterministic constraint accepted by a search or listing operation.
  Filter definitions use short Service-local identifiers and can be embedded or linked and
  paginated.

Service Origin
: The canonical ASCII serialization of the origin from which the Service Document was retrieved. The
  Service Origin identifies the Service.

Local Resource Identifier
: A Service-created and Service-managed string that identifies a Collection or Offering within one
  resource-type namespace at that Service.

Resource Identity
: The tuple of Service Origin, resource type, and Local Resource Identifier. An Agent composes this
  tuple; a Service emits the Local Resource Identifier in the resource representation.

Resource Reference
: An origin-relative absolute-path reference or an absolute URL that locates a browser
  representation, schema, subsequent operation, or other referenced resource. A Resource Reference
  does not define Resource Identity.

MCP Endpoint
: A remote Model Context Protocol Streamable HTTP connection target advertised by a Service. An MCP
  Endpoint is not a browser link, ODP operation, or ODP Action.

Top-Level Document
: The outermost JSON object carried by one ODP request or response body. Objects nested within that
  object, including terse result items, are not Top-Level Documents.

Subsequent Operation
: An operation linked from an ODP resource whose semantics can be defined by ODP, AEP, MPP, x402, or
  another protocol.

# Roles

## Agent Role

An Agent consumes Service Documents and advertised ODP resources. It selects advertised operations,
constructs their fixed paths from `http.endpoint_base`, interprets Service-defined attributes using
the applicable Attribute Schema, and honors live HTTP authentication and payment challenges.

An Agent MUST NOT assume that an unadvertised ODP operation exists. An Agent MUST construct only the
fixed paths defined by this document. An Agent MUST treat content received from a directory as
discovery metadata rather than authoritative Offering data.

## Service Role

A Service publishes its Service Document and serves the ODP operations it advertises. The Service is
authoritative for its Collections, Offerings, Attribute Schemas, filters, access policy, and
subsequent-operation links.

A Service MUST NOT advertise an ODP operation that it does not support. A Service MUST keep
operation metadata consistent with the behavior available to the Agent under the applicable access
policy.

## Directory Relationship

A directory is not an ODP protocol role. It is an optional discovery facility that helps an Agent
find Services by indexing public Service metadata. A directory can cache Service documents subject
to its own refresh policy, but it is not authoritative for Service-owned catalog data.

This document defines no directory query, suggestion, filter, facet, count, ranking, or response
wire format. A directory can index localized Service `name`, `description`, and `keywords` values
and combine them with directory-owned signals. Those behaviors belong to the directory
implementation and do not become ODP operations or ODP conformance requirements.

Directory suggestions and facets describe the directory's Service index. Offering-search refinements
describe candidate values for effective Service-owned Filter Definitions. An Agent MUST NOT treat
either one as the other, and MUST retrieve the current Service Document and catalog data from a
selected Service before treating them as authoritative.

ODP conformance does not depend on the use, availability, or implementation of a directory.

# Resource Identity and References

## Service Identity

The Service Origin identifies a Service. An Agent MUST derive it from the final Service Document
response URL using the ASCII serialization algorithm in {{RFC6454}}. The canonical serialization
MUST use a lowercase scheme and host, MUST omit the default port, and MUST contain no path, query,
fragment, or user information.

The Service Origin scheme MUST be `https`. For local development, `http` is permitted only when the
host is syntactically exactly `localhost`, `127.0.0.1`, or `[::1]`. Resolving another host name to a
loopback address does not qualify.

A Service Document MUST NOT declare another value as the Service's identity. Control of the Service
Origin is established through the origin and transport security rather than a self-asserted global
identifier. Changing the Service Origin changes the Service identity.

## Local Resource Identifiers

Every Collection and Offering representation MUST contain `id`, a Local Resource Identifier created
and managed by the Service. ODP does not prescribe the Service's identifier-generation algorithm.

A Local Resource Identifier MUST contain between 1 and 128 ASCII characters. Every character MUST be
an ASCII letter, decimal digit, hyphen (`-`), period (`.`), underscore (`_`), or tilde (`~`). The
complete identifier MUST NOT be `.` or `..`. A Service MUST keep the identifier stable for the
resource's lifetime and MUST NOT assign it to another resource in the same resource-type namespace.
Services SHOULD use UUIDs where practical. A Service whose internal identifier does not satisfy this
syntax MUST map it to a stable public ODP identifier.

Collections and Offerings have separate identifier namespaces. The same Local Resource Identifier
MAY identify one Collection and one Offering at a Service. It MUST NOT identify two Collections or
two Offerings at that Service.

Agents MUST treat a Local Resource Identifier as opaque. Comparison is exact and case-sensitive.
Agents MUST NOT trim, case fold, URL-decode, parse, or infer semantics from an identifier.

## Complete Resource Identity

The Resource Identity of a Collection or Offering is the tuple:

~~~
(Service Origin, resource type, Local Resource Identifier)
~~~

The resource type is `collection` or `offering`. Agent implementations SHOULD expose Resource
Identity as a structured value. They SHOULD NOT create an externally visible concatenated form whose
delimiters or escaping would constitute an additional identifier syntax.

The Service is responsible for the Local Resource Identifier. The Agent is responsible for
associating it with the Service Origin and resource type established by the representation context.
The Service does not need to serialize the complete tuple in each representation.

An Agent MUST compare all three tuple members when determining whether two representations identify
the same resource. A Resource Reference, response URL, name, schema, or attribute change does not by
itself change Resource Identity.

## Resource References

Fields defined as Resource References, including Service links, Collection and Offering `web_url`,
image `src`, and subsequent-operation `href` values, MUST contain one of:

* an origin-relative absolute-path reference beginning with exactly one `/`, resolved against the
  Service Origin according to {{RFC3986}}; or
* an absolute URL using the lowercase `https` scheme.

For local development, an absolute URL MAY use the lowercase `http` scheme only with a host
syntactically equal to `localhost`, `127.0.0.1`, or `[::1]`. Path-relative references,
parent-relative references, scheme-relative references, fragments, and user information are
prohibited.

A same-origin reference SHOULD use the origin-relative form. A cross-origin reference MUST use an
absolute URL. Non-ASCII URL components MUST be percent-encoded before serialization.

An Agent MUST resolve an origin-relative Resource Reference against the Service Origin, not against
the path of the representation containing it.

Following a cross-origin reference does not change the Service Origin or Resource Identity of the
referring ODP resource. An Agent MUST apply origin and credential policy independently to the
resolved target as required by the Security Considerations.

# Versioning and Compatibility

## Version Syntax

Every Top-Level Document MUST contain `odp_version`. Its value is a JSON string in `MAJOR.MINOR`
form. `MAJOR` and `MINOR` are unsigned decimal integers without leading zeroes except for the value
`0`. The protocol version defined by this document is `1.0`.

Nested objects MUST NOT repeat `odp_version` unless a specification explicitly defines the nested
object as an independently processable Top-Level Document. Terse items in a list or search response
inherit the version of their containing Top-Level Document.

## Compatibility Rules

The major version identifies the compatibility family. An implementation MUST reject a Top-Level
Document whose major version it does not support. Minor versions within one major version are
backward compatible.

A minor-version revision MAY add optional fields, optional enum values, optional capabilities, or
clarifications that preserve existing wire behavior. It MUST NOT remove or redefine an existing
field, value, operation, error, or requirement. It MUST NOT make a new field or capability mandatory
for implementations of an earlier minor version in the same major-version family.

An implementation supporting a major version MUST process Top-Level Documents carrying any minor
version in that major-version family according to the unknown-field and unknown-value rules in this
document. Implementations MUST NOT infer support for an optional capability from a higher minor
version.

Each request and response Top-Level Document declares the version governing that document. The
version is not inherited across HTTP exchanges. A Service receiving a supported major version MUST
apply same-major compatibility rules even when its preferred minor version differs.

# HTTP Media Types and Negotiation

## ODP JSON Media Type

The media type for ODP request and response documents is `application/odp+json` and uses the JSON
structured syntax suffix defined by {{RFC6839}}. The media type has no required or optional
parameters. Parameters do not select or modify the ODP protocol version. The `odp_version` member is
the sole protocol-version authority.

An Agent SHOULD send `Accept: application/odp+json` when requesting an ODP resource. A Service MAY
return an ODP representation when `Accept` is absent, permits `*/*`, or permits
`application/odp+json`. If the request's `Accept` field excludes `application/odp+json`, the Service
MUST respond with `406 Not Acceptable`.

A request carrying an ODP Top-Level Document MUST use a `Content-Type` whose media-type essence is
`application/odp+json`. A Service MUST respond with `415 Unsupported Media Type` when a request body
intended for an ODP operation has a missing, malformed, or different media type.

A successful response carrying an ODP Top-Level Document MUST use a `Content-Type` whose media-type
essence is `application/odp+json`. An Agent MUST reject a successful ODP response with a missing,
malformed, or different media type.

Media-type essence comparison is case-insensitive. Receivers MUST ignore syntactically valid media
type parameters and MUST NOT interpret a `version` parameter or any other parameter as an ODP
version declaration. HTTP Problem Details responses use `application/problem+json`. Attribute Schema
documents use `application/schema+json`.

## No Separate Version Negotiation

Implementations MUST NOT negotiate the ODP version through a media-type parameter or a separate ODP
version header. An Agent determines whether it can process a received Top-Level Document from
`odp_version` and the compatibility rules in this document.

# Discovery Architecture

## Service Discovery

An Agent can begin with a known Service origin or obtain candidate Service origins from a directory
or another source. When a directory is used, the result of the first stage is a set of candidate
Services. The result is not a cross-Service Offering search result.

## Service Inspection

An Agent retrieves the Service Document from `/.well-known/odp` at the Service origin. The Service
Document advertises the ODP operations available to the Agent. The Agent constructs only advertised
operations using the endpoint rules in this document.

# Service Document

## Retrieval and Access

The Service Document is the response to `GET /.well-known/odp`. This request MUST be available
without enrollment, authentication, or payment. A Service can enforce access policy on catalog
operations advertised by the document.

The successful response MUST be an ODP JSON Top-Level Document. The Service Document MUST be a flat
JSON object and MUST contain `odp_version`, `name`, `description`, `language`, `localizations`,
`operations`, and `http`. It MAY contain `branding`, `documentation_url`, `keywords`, `mcp`,
`protocols`, `search_capabilities`, `status_url`, `support_url`, and `website_url`. It MUST NOT
contain a self-asserted Service identifier or `web_url`.

`name` is a non-empty string of at most 128 Unicode code points. `description` is a non-empty string
of at most 1024 Unicode code points. `keywords` is an array of at most 32 unique freeform strings,
each containing 1 through 64 Unicode code points and collectively containing at most 1024 Unicode
code points. A keyword MUST begin and end with a non-whitespace code point. A Service SHOULD omit
`keywords` when it has none.

Keywords are localized Service-discovery hints in the language identified by `language`. They do not
draw from a protocol-defined vocabulary, advertise accepted query terms, enumerate a catalog, or
define filters. ODP defines no case folding, normalization, stemming, or semantic equivalence for
them; array uniqueness uses JSON string equality. An Agent MUST NOT restrict a Collection or
Offering search query to Service keywords or assume that a Service supports keyword enumeration or
query completion.

## Service Links

The Service Document MAY include the following Resource References:

* `website_url` identifies the human-facing Service website or storefront;
* `documentation_url` identifies human-readable documentation for using the Service;
* `support_url` identifies the Service's support destination; and
* `status_url` identifies the Service's operational status page.

These links are descriptive metadata. Their presence does not advertise an ODP operation, alter an
operation's access policy, or replace the machine-readable OpenAPI reference in `http.openapi`.
`website_url` is not a base URL for other Resource References. In particular, a Collection or
Offering `web_url` is resolved against the Service Origin. A Service whose browser resources use a
different origin supplies an absolute URL in each applicable Resource Reference.

## MCP Endpoints

`mcp`, when present, is a non-empty array of remote MCP Endpoint descriptors. A Service with no MCP
Endpoint omits `mcp` rather than serializing an empty array.

Each descriptor MUST contain `type` and `url` and MAY contain `name` and `description`. `type` MUST
be `streamable-http`, identifying the MCP Streamable HTTP transport {{MCP}}. `url` is a Resource
Reference to the remote MCP Endpoint. `name`, when present, is a non-empty human-readable label of
no more than 128 Unicode code points. `description`, when present, is a non-empty explanation of the
endpoint's purpose containing no more than 1024 Unicode code points. `name` and `description` use
the Service Document's `language` and localization rules.

An MCP descriptor locates a connection surface; it does not describe an individual MCP tool. A
Service SHOULD use one descriptor for tools exposed through one MCP connection surface and SHOULD
use multiple descriptors only for distinct connection surfaces. Array order has no protocol
semantics.

Retrieving, validating, or indexing a Service Document MUST NOT invoke an advertised MCP Endpoint.
An MCP-capable client connects only when its caller's operation requires that interface. MCP remains
authoritative for capability discovery, version negotiation, tools, resources, prompts,
authorization, and request behavior. The presence of an MCP descriptor does not state that the
endpoint is public and does not authorize an Agent to send ODP, AEP, payment, or other credentials.

## Branding

`branding`, when present, contains exactly `icon` and `logo`. Each member contains a required
Resource Reference `src` and MAY contain a `type` of `image/svg+xml`, `image/png`, or `image/webp`.
`type` is a media-type hint available before retrieval. A Service SHOULD provide it when the
Resource Reference does not have a filename extension that identifies the image format. `icon`
identifies a Service mark intended for a square presentation canvas. `logo` identifies a Service
mark intended for a horizontal 4:1 presentation canvas. Services SHOULD provide sufficient source
resolution to avoid upscaling. SVG resources MUST provide positive intrinsic dimensions or a
positive view-box width and height.

A client that normalizes branding for storage or presentation MUST preserve the source aspect ratio
and MUST NOT crop or stretch the source. The client fits and centers `icon` within a square canvas
and `logo` within a 4:1 canvas. Unused canvas pixels MUST be transparent when the normalized format
supports transparency. The RECOMMENDED normalized dimensions are 200 by 200 pixels for `icon` and
400 by 100 pixels for `logo`.

Branding retrieval is anonymous. A client MUST NOT attach AEP credentials, payment credentials,
cookies, or authorization fields. When `type` is present, the successful response media-type essence
MUST equal the advertised value. A branding response body is limited to 1,048,576 bytes and five
redirects. Redirect and network-address policy follows Supporting Resource Retrieval. Branding
content is untrusted input. A client that displays SVG MUST either sanitize and safely isolate it or
render it to a non-active raster representation before display.

`protocols` advertises Service-wide support for enrollment and payment protocols. It contains at
least one of `enrollment` or `payments`. An unsupported category is omitted rather than serialized
as an empty array.

`enrollment`, when present, is the single-item array `[{"name":"aep"}]`, identifying AEP {{AEP}}. An
enrollment descriptor contains only `name`.

`payments`, when present, is a non-empty array of no more than two payment descriptors. Each
descriptor contains `name` and `authentication` and MAY contain `options`. `name` is `mpp`,
identifying the `Payment` HTTP Authentication Scheme {{MPP}}, or `x402`, identifying the x402
protocol {{X402}}. Names MUST NOT be duplicated. When both descriptors are present, their array
order expresses Service preference. `authentication` is `not-required` or `required` and states
whether the Agent must authenticate to the Service before using that payment protocol. A `required`
value requires the Service Document to advertise an enrollment protocol.

`options`, when present, is a non-empty array of no more than 16 unique payment-option names drawn
from `algorand`, `aptos`, `arbitrum`, `avalanche`, `base`, `card`, `ethereum`, `hedera`, `inflow`,
`lightning`, `polygon`, `solana`, `stellar`, `stripe`, `tempo`, and `ton`. Each name is a compact,
human-consumable compatibility label. It does not replace protocol-specific method, scheme, network,
chain, asset, or settlement terms. A Service MUST advertise an option only under a payment protocol
through which it accepts that option. Omitting `options` means that the Service advertises the
payment protocol without advertising detailed option compatibility.

Protocol advertisement describes support and the authentication prerequisite for each payment rail;
it does not guarantee that a payment protocol is accepted by every ODP operation, catalog resource,
or Action. A missing category means only that support is not advertised. An Agent and directory MAY
derive a Service-support summary from this field. Recognition of an option by ODP does not imply
that an Agent implementation supports or is configured to use it. A live HTTP response remains
authoritative for the request that produced it.

## Language Selection

`language` MUST be the {{RFC5646}} language tag of the representation. `localizations` MUST be a
non-empty array of no more than 16 unique RFC 5646 language tags available for the Service metadata.
It MUST include `language`. These fields describe the Service Document metadata and do not assert
which localizations are available for Collections or Offerings.

An Agent requests a preferred representation using `Accept-Language`. A Service supporting multiple
representations MUST select a language using the Lookup scheme in {{RFC4647}}. If no requested range
matches, it MUST return its default representation rather than `406 Not Acceptable`. A localized
response MUST include `Content-Language` and `Vary: Accept-Language`. Entity tags MUST distinguish
representation variants. ODP does not define a language query parameter.

## HTTP Endpoint Base

`http` MUST be an object containing `endpoint_base` and MAY contain `openapi`. `endpoint_base` is an
origin-relative absolute-path reference beginning with exactly one `/`, MUST NOT contain a query or
fragment, and MUST contain no more than 2048 ASCII characters. The value MAY end in `/`.

`openapi`, when present, contains exactly one member, `url`, whose value is a Resource Reference to
a reusable OpenAPI 3.1 document. It supplies the default OpenAPI document for Actions whose OpenAPI
target omits `url`. An Action-level `url` overrides this Service-wide value. Advertising `openapi`
does not require an Action to use it and does not make OpenAPI a dependency of ODP navigation.

An Agent constructs an operation URL by removing any trailing slash from `endpoint_base`, appending
one `/`, and appending the fixed path from the following table. Identifier placeholders are replaced
verbatim with valid Local Resource Identifiers; percent-encoding or decoding is not performed.

| Operation identifier        | Method | Fixed path                              |
| --------------------------- | ------ | --------------------------------------- |
| `list-collections`          | `GET`  | `collections`                           |
| `search-collections`        | `POST` | `collections/search`                    |
| `get-collection`            | `GET`  | `collections/{collection_id}`           |
| `list-collection-offerings` | `GET`  | `collections/{collection_id}/offerings` |
| `list-offerings`            | `GET`  | `offerings`                             |
| `search-offerings`          | `POST` | `offerings/search`                      |
| `get-offering`              | `GET`  | `offerings/{offering_id}`               |

Query parameters can modify a request where an operation defines them. They are not part of Resource
Identity and MUST NOT be used to carry Collection or Offering identifiers.

## Representation Selection

Every Collection and Offering operation supports the `representation` query parameter. Its value
MUST be `terse` or `full`. An absent parameter selects the operation default in the following table.

| Operation identifier        | Default representation |
| --------------------------- | ---------------------- |
| `list-collections`          | Terse items            |
| `search-collections`        | Terse items            |
| `get-collection`            | Full Collection        |
| `list-collection-offerings` | Terse items            |
| `list-offerings`            | Terse items            |
| `search-offerings`          | Terse items            |
| `get-offering`              | Full Offering          |

`representation=terse` selects Terse Representations and `representation=full` selects Full
Representations regardless of the operation default. On a list or search operation, the selection
applies to every Collection or Offering item in the response, not to the page envelope. A request
MUST NOT contain more than one `representation` parameter. A Service MUST reject an unsupported or
repeated value with `400 Bad Request`.

The query parameter does not change Resource Identity. HTTP caches distinguish query-target variants
according to normal HTTP cache-key rules. Pagination and response limits apply independently of the
selected representation. An Agent requesting Full Representations from a list or search operation
MUST NOT assume that the Service will increase its page or response limits.

## Operation Advertisement

`operations` MUST be an array of no more than seven Operation Descriptors. Every descriptor MUST
contain exactly `name` and `authentication`. `name` is an operation identifier from the preceding
table and MUST be unique in the array. `authentication` is one of `not-required`, `optional`, or
`required`:

| Value          | Meaning                                                                 |
| -------------- | ----------------------------------------------------------------------- |
| `not-required` | The operation is usable without Service authentication.                 |
| `optional`     | The operation is usable anonymously; authentication can expand content. |
| `required`     | The operation requires Service authentication before it can succeed.    |

An `optional` or `required` value requires the Service Document to advertise an enrollment protocol.
`optional` does not require every anonymous response to differ from an authenticated response. It
states that the operation supports both contexts and that authentication can affect the visible
catalog content.

An Agent MUST NOT invoke an ODP operation that the Service Document does not advertise. Every
conformant Service MUST advertise and implement `list-offerings` and `get-offering`; consequently,
the array contains at least two descriptors. The remaining operations are optional and are
implemented only when advertised.

## Processing Limits

The decoded UTF-8 Service Document MUST NOT exceed 65,536 bytes or a JSON nesting depth of 8. String
and array limits in this section are measured after JSON decoding. A Service MUST produce a document
within every limit. An Agent MUST reject the entire document if a required member is missing, a
limit is exceeded, or the document is otherwise invalid; it MUST NOT act on a partially parsed
Service Document.

An Agent MUST follow no more than five redirects while retrieving the Service Document. Every
redirect target MUST have the same scheme, host, and effective port as the preceding request. The
Agent MUST reject cross-origin redirects, transport-security downgrades, and redirect loops.

# HTTP Caching

HTTP cache directives and validators are authoritative. When a response supplies no freshness
information, an SDK SHOULD use configurable fallback freshness lifetimes of four hours for Service
Documents, one hour for Collections, five minutes for Offerings, zero seconds for search responses,
one hour for Filter and Sort Definitions, and 24 hours for Attribute Schemas. Each resource class
MUST be configurable independently. A fallback does not override `Cache-Control`, `Expires`,
validators, or other HTTP caching semantics.

An Agent cache MUST partition anonymous responses from responses obtained with Service
authentication. It MUST NOT reuse an authenticated representation, page, schema, or capability
document for an anonymous request or for a different authentication context. This requirement
applies even when the URI and selected representation are identical.

# Pagination

## Page Envelope

Every successful list or search response is an ODP Top-Level Document containing `odp_version` and
`items`. `items` is an array and can be empty. A response containing another page MUST also contain
`next`. The final page MUST omit `next`; an empty `items` array alone does not prove that the
sequence ended.

A page MAY contain `auth_expands` with the only valid value `true`. Its presence states that
retrying the operation with acceptable Service authentication can expose additional items or
additional fields in returned items under the current query. It does not identify, count, or
describe protected content. A Service MUST omit the member rather than serialize `false`.

`next` is a Resource Reference of no more than 2048 ASCII characters. It MUST resolve to the same
origin as the initial operation. An Agent MUST preserve it exactly and MUST NOT decode, modify,
construct, or derive behavior from its path, query, or embedded continuation token.

ODP does not define previous-page traversal, numeric page indexes, offsets, or total-result counts.
An Agent that needs to restart traversal repeats the initial operation request.

## Continuation Requests

An Agent retrieves `next` with `GET`. The response is another page envelope governed by the same
representation and access context. Only omission of `next` marks the end of the sequence. A
continuation response MUST advance traversal and MUST NOT return the request URL as its own `next`.

The Service chooses the continuation URL and preserves every input needed to continue the original
operation, including representation, filters, search terms, sorting, access context, and page-size
policy. The Agent does not repeat the original request body or reconstruct those inputs. A
continuation link from a `POST` search is still retrieved with `GET`.

Every initial list and search operation accepts `limit`, an integer from 1 through 100 that requests
the maximum number of items per page. `GET` operations carry it as a query parameter; `POST` search
operations carry it as a top-level request-body member. A Service MAY return fewer items than
requested. A Service chooses its default page size when `limit` is absent. An Agent-oriented SDK
SHOULD use a configurable initial page size with a default of 50 and MAY request fewer items when
its caller's remaining overall result limit is smaller.

## Continuation Semantics

A continuation sequence contains a stable logical sequence of Resource Identities and their order.
Within one traversal, the Service MUST NOT change that sequence or return the same Resource Identity
more than once. Resource representations can reflect changes made after the initial request, but
membership and ordering in the continuation sequence remain stable. An item's `id` is the final
deterministic ordering tie-breaker.

Each `next` link MUST remain usable for at least one hour after issuance. A Service MAY choose a
longer lifetime. An expired continuation MUST NOT silently restart traversal; the Service returns an
expired-continuation problem, and an Agent-oriented SDK reports that failure to its caller.

The continuation link is an interface contract, not a server storage model. Its path or query MAY
contain a self-contained authenticated cursor or a reference to server-managed state. A stateless
cursor can carry a query digest, snapshot or revision, keyset boundary, access-context binding, and
expiration. Clients cannot distinguish stateless and stateful continuation and MUST treat both
identically.

A self-contained cursor embedded in `next` MUST be integrity protected. It MUST NOT disclose
credentials, private catalog data, access-policy details, or other sensitive state. A Service SHOULD
encrypt a self-contained cursor whose continuation state is confidential. A Service MUST validate
every cursor as untrusted input and MUST NOT treat possession of a cursor as authorization.

## Agent Iteration

An Agent-oriented SDK SHOULD expose list and search results as asynchronous iterables that retrieve
continuation pages automatically. Its ordinary item interface SHOULD yield Collection or Offering
representations rather than page envelopes or continuation links. A lower-level page interface MAY
expose `items` and `next` for callers that require explicit page control.

An overall caller result limit is independent of the Service page `limit`. Reaching the caller's
limit stops local iteration and does not imply that the Service sequence ended. An SDK MUST NOT
fetch another page after the caller stops iteration.

## Page Caching and Conditional Requests

Each page request has its own HTTP cache key and validators under {{RFC9110}} and {{RFC9111}}. For
`GET` pages, a Service SHOULD provide an entity tag and honor conditional retrieval such as
`If-None-Match`; an unchanged conditional `GET` returns `304 Not Modified`. Collection and Offering
page fallbacks use their applicable resource-class freshness lifetime. Filter Definition pages use
the Filter Definition fallback.

Search responses, including their `GET` continuation pages, retain the zero-second fallback
freshness lifetime. A `POST` search response is cacheable only when explicit HTTP semantics permit
it. A continuation link does not override cache directives, create a shared-cache authorization, or
make a private response public.

## Catalog Discovery

Collections are optional navigation resources. A Service can expose Offering search without
Collections, Collection search without a hierarchy, or both. An Offering can belong to zero, one, or
multiple Collections.

List, search, and retrieval operations use the representation defaults and overrides defined in
Representation Selection. An Agent obtains an individual Full Representation by applying the terse
item's `id` to the applicable fixed retrieval operation.

# Terse and Full Representations

## Stable Field Placement

A Terse Representation and its corresponding Full Representation describe the same Resource
Identity. A field has the same name, location, type, and semantics in both representations. A
Service MUST NOT move Service-defined attributes or core fields into a separate preview, summary, or
representation-specific container.

Every Terse Representation MUST contain `id` and `name`. Other fields are optional in a Terse
Representation unless their resource contract requires them. A Service selects which optional fields
to include according to the usefulness and cost of those fields. It MAY include every field from the
Full Representation. A field present in both representations MUST have equivalent meaning; volatile
values MAY differ because the representations were generated at different times.

A Terse Representation omits fields or nested object members; it does not silently truncate an
included scalar or array. An included object can omit members recursively. A field whose own
contract explicitly defines truncation, pagination, or summary semantics follows that contract.

A Full Representation MUST contain every ODP field available for that resource under the request's
current access policy. This completeness requirement does not require inapplicable optional fields,
fields withheld by access policy, or data that the Service does not possess.

A Collection or Offering representation MAY contain `auth_expands` with the only valid value `true`.
Its presence states that retrying its retrieval with acceptable Service authentication can expose
additional fields for that resource. The member does not identify protected fields, promise access
to a particular principal, or replace a live authentication challenge. A Service MUST omit the
member rather than serialize `false`.

## Detail Fields

A Terse Representation MAY contain `detail_fields`. A Full Representation MUST NOT contain
`detail_fields`. The value is a non-empty array of no more than 32 unique JSON Pointer strings as
defined by {{RFC6901}}. Each pointer MUST contain no more than 256 printable ASCII characters, MUST
begin with `/`, and MUST NOT use the URI fragment representation of a JSON Pointer.

Each pointer identifies a field present in the corresponding Full Representation and absent from the
Terse Representation. A pointer to an omitted object or array covers its complete subtree. Top-level
document metadata inherited by an embedded Terse Representation, including `odp_version`, is not a
detail field.

When `detail_fields` is present, it MUST exhaustively identify the minimal omitted field subtrees.
When an exhaustive list would exceed a limit in this section, the Service MUST omit `detail_fields`
instead of returning a partial list. Absence of `detail_fields` makes no claim about whether the
Full Representation contains additional fields.

`detail_fields` advertises only what an Agent obtains by retrieving the Full Representation. It does
not advertise or enable field projection, grant access to the Full Representation, or override a
live authentication or payment challenge. A Service MUST NOT disclose protected field existence
through `detail_fields` when the current principal is not permitted to learn that information.

## No Field Projection

ODP version 1.0 does not define a request syntax for selecting arbitrary resource fields. An Agent
MUST NOT infer field-projection support from `detail_fields`, an Attribute Schema, or an unknown
query parameter. A future compatible revision can advertise and define projection independently.

Collections and Offerings MAY include a `web_url` link for a human-facing browser experience. The
browser representation is informative for Agent operation and does not replace the machine-readable
ODP resource.

## Resource Images

A Collection or Offering MAY contain `images`, a non-empty ordered array of no more than 16 image
descriptors. The first descriptor identifies the primary image. Each descriptor MUST contain `src`,
a Resource Reference, and MAY contain `alt`, `height`, `type`, and `width`. Two descriptors in one
array MUST NOT contain the same `src` value.

`alt`, when present, is non-empty alternative text of no more than 1024 Unicode code points in the
language of the containing representation. `height` and `width`, when present, are positive integer
intrinsic dimensions in CSS pixels no greater than 65535. `type`, when present, is a media-type hint
of `image/avif`, `image/jpeg`, `image/png`, `image/svg+xml`, or `image/webp`.

A Terse Representation MAY include only the primary image even when the Full Representation contains
additional images. This is the sole summary behavior of `images`; descriptors themselves MUST NOT be
partially serialized. Omitting `images` from a Terse Representation makes no claim that the Full
Representation has no images.

Image retrieval is anonymous. A client MUST NOT attach AEP credentials, payment credentials,
cookies, or caller authorization fields. The response `Content-Type` is authoritative. When an
advertised `type` differs from the response media-type essence or the response is not a supported
image type, a client rejects only that image. Image content is untrusted input and remains subject
to the client's network, decoding, rendering, and resource limits.

# Collections

## Collection Search

The `search-collections` operation accepts an ODP Top-Level Document containing `odp_version` and at
least one of `query` or `parent_id`. It MAY also contain `limit`. A request containing neither
search criterion is invalid; an Agent uses `list-collections` for an unconstrained sequence.

`query` is a non-empty string of no more than 256 Unicode code points and MUST contain at least one
non-whitespace character. It conveys text-search intent to the Service. The Service owns query
interpretation, matching, indexing, and relevance. It can use lexical, full-text, language-aware,
semantic, or other matching over Collection metadata visible under the request's access and language
context. ODP does not define tokenization, stemming, case folding, searchable fields, or a portable
relevance algorithm. An Agent MUST NOT assume that the same query produces equivalent matches at
different Services.

`parent_id` defines an exact hierarchy constraint. An omitted `parent_id` applies no hierarchy
constraint. A JSON `null` value selects root Collections, which omit `parent_ids`. A Local Resource
Identifier selects Collections whose `parent_ids` contains that identifier, meaning its direct
children. It does not select the named Collection or recursively select descendants.

When both `query` and `parent_id` are present, a Collection MUST satisfy both criteria. The
`parent_id` predicate retains its exact protocol-defined meaning regardless of how the Service
interprets `query`.

The Service chooses result ordering. It can use relevance, curated taxonomy order, popularity, or
another Service policy, and ODP version 1.0 defines no client-selected Collection sort. The common
pagination contract requires the chosen logical sequence to remain stable during one traversal and
uses `id` as the final ordering tie-breaker. An Agent MUST NOT reorder results before exposing them
unless its caller explicitly requests local presentation ordering.

The successful response is a page envelope containing Collection Representations selected by the
common `representation` query parameter. No matches produce `200 OK` with an empty `items` array.
Malformed request bodies or unsupported member values produce an `INVALID_REQUEST` problem. The
request and response use `application/odp+json`.

## Collection Envelope

A Full Collection Representation MUST contain `odp_version`, `id`, and `name`. It MAY contain
`description`, `images`, `language`, `localizations`, `parent_ids`, `web_url`, and
`search_capabilities`. Other Collection capabilities are defined by the operation or feature that
uses them. An optional field with no applicable or available value is omitted rather than serialized
as an empty value.

`language` and `localizations` have the syntax and meaning defined for Service Document language
metadata, but describe this Collection. They are omitted when the Collection uses the applicable
language metadata inherited from its containing response or Service Document. Collection retrieval
uses the same `Accept-Language`, Lookup, fallback, `Content-Language`, `Vary`, and entity-tag rules
as Service Document retrieval.

When present, `parent_ids` MUST be a non-empty array of unique Local Resource Identifiers. Every
identifier names a direct parent Collection at the same Service. An omitted `parent_ids` identifies
a root Collection. A Service can publish multiple roots or a flat set in which every Collection is a
root.

A Terse Collection follows the common Terse Representation contract. It MUST contain `id` and
`name`; it can omit any other optional terse field, including `parent_ids`, and can use
`detail_fields` to identify fields available through full retrieval.

## Hierarchy

Collection parent relationships form a directed acyclic graph. A Collection MAY have more than one
parent. A Collection MUST NOT name itself as a parent, every parent identifier MUST resolve to a
Collection visible under the same access context, and following parent relationships MUST NOT
produce a cycle.

The maximum path from a Collection through successive parents is 32 edges. A conforming Service MUST
NOT publish a deeper hierarchy. Breadth and parent-array cardinality are governed by the common
resource and response limits rather than the depth limit.

`parent_ids` is the sole serialized source of hierarchy edges. Collections do not duplicate edges in
a `child_ids` field. An Agent discovers direct children through Collection search constrained by the
parent identifier. The Collection search contract defines that constraint.

An Agent traversing hierarchy data MUST track visited Resource Identities. When an edge closes a
cycle, exceeds the depth limit, names the current Collection, or names a missing Collection, the
Agent MUST ignore that edge. The invalid edge does not invalidate unrelated Collections, hierarchy
edges, Offering memberships, or operations.

## Offering Membership

When present, `collection_ids` MUST be a non-empty array of unique Local Resource Identifiers. Each
identifier names a Collection at the same Service in which the Offering is a direct member. An
omitted `collection_ids` means that the Offering has no Collection membership. A Terse Offering MAY
omit `collection_ids` under the common Terse Representation rules.

The `list-collection-offerings` operation is the inverse query over this relationship: it returns
Offerings whose `collection_ids` contains the requested Collection identifier. A Service MUST keep
the operation result consistent with the Offering membership it publishes.

Hierarchy and membership are independent. Membership in a child Collection does not imply membership
in any ancestor Collection. ODP version 1.0 does not define implicit descendant expansion. Offering
search can request explicit descendant inclusion without changing direct membership semantics.

Every `collection_ids` entry MUST resolve to a Collection visible under the same access context. An
Agent MUST ignore a missing membership edge without rejecting the Offering or unrelated memberships.

## No Synthetic Collection Identity

ODP does not define an "All Offerings" Collection, reserve a Collection identifier for that purpose,
or assign Resource Identity to a client-side convenience view. An Agent uses `list-offerings` for
the complete accessible Offering sequence. A Service can publish an ordinary Collection with
equivalent business meaning, and an SDK can label `list-offerings` for user-interface convenience
without creating an ODP resource.

# Offerings

## Offering Search

The `search-offerings` operation accepts an ODP Top-Level Document containing `odp_version` and at
least one of `query` or `filters`. It MAY also contain `collection_id`, `include_descendants`,
`sort`, `refinements`, and `limit`. An Agent uses `list-offerings` for an unconstrained sequence and
`list-collection-offerings` for the unconstrained direct members of one Collection.

`query` is a non-empty string of no more than 256 Unicode code points and MUST contain at least one
non-whitespace character. It conveys text-search intent to the Service. The Service owns query
interpretation, matching, indexing, and relevance. It can use lexical, full-text, language-aware,
semantic, or other matching over Offering metadata and Service-defined attributes visible under the
request's access and language context. ODP does not define tokenization, stemming, case folding,
searchable fields, or a portable relevance algorithm. An Agent MUST NOT assume that the same query
produces equivalent matches at different Services.

`filters` and `sort` use the Filter Expression and Sort Definition contracts in this document. When
`query` and `filters` are both present, an Offering MUST satisfy the Service-interpreted query and
every Filter Expression. An omitted `sort` preserves the Service's preferred ordering.

`collection_id` is a Local Resource Identifier that constrains results to Offerings in the named
Collection. The Collection MUST resolve under the current access context. Otherwise, the Service
returns `404 Not Found` with a `NOT_FOUND` problem. A Service MAY use the same response when
revealing that an inaccessible Collection exists would disclose protected information.

`include_descendants` is a Boolean and MUST NOT appear without `collection_id`. Its default is
`false`. When false or omitted, an Offering matches the Collection constraint only when its
`collection_ids` contains `collection_id`. When true, an Offering matches when it is a direct member
of the named Collection or any Collection reachable by following child relationships from it. This
expansion does not alter or imply Offering membership.

Descendant expansion observes the common Collection graph depth and invalid-edge rules. A Collection
reachable through multiple paths is processed once. An Offering belonging to multiple included
Collections appears at most once in the result sequence.

The Service chooses result ordering. It can use relevance, curated ranking, popularity, or another
Service policy, and ODP version 1.0 defines no client-selected Offering sort. The common pagination
contract requires the chosen logical sequence to remain stable during one traversal and uses `id` as
the final ordering tie-breaker. An Agent MUST NOT reorder results before exposing them unless its
caller explicitly requests local presentation ordering.

The successful response is a page envelope containing Offering Representations selected by the
common `representation` query parameter. No matches produce `200 OK` with an empty `items` array.
Malformed request bodies or unsupported member values produce an `INVALID_REQUEST` problem. The
request and response use `application/odp+json`.

When requested, the initial response MAY also contain the bounded Refinement Groups defined below. A
continuation response MUST omit `refinements`. Refinements describe the complete logical result set
for the initial request, not only the Offerings serialized on its first page.

## Offering Envelope

A Full Offering Representation MUST contain `odp_version`, `id`, and `name`. It MAY contain
`description`, `images`, `language`, `localizations`, `web_url`, `collection_ids`, `price`,
`schema`, `attributes`, and `actions`. An optional field with no applicable or available value is
omitted. In particular, a Service MUST NOT serialize empty `attributes`, `collection_ids`, or
`actions` merely to declare that the capability is unused.

`language` and `localizations` have the syntax and meaning defined for Service Document language
metadata, but describe this Offering. They are omitted when the Offering uses the applicable
language metadata inherited from its containing response or Service Document. A containing response
can establish language metadata for its embedded items. The nearest metadata in the order Offering,
containing response, then Service Document applies. Offering retrieval uses the same
`Accept-Language`, Lookup, fallback, `Content-Language`, `Vary`, and entity-tag rules as Service
Document retrieval. `Content-Language` identifies the language actually selected for the HTTP
representation.

A Terse Offering follows the common Terse Representation contract. It MUST contain `id` and `name`.
It MAY include `price` and any other optional terse field except `actions`. Absence of `web_url`,
`price`, `schema`, `attributes`, or another optional field from a Terse Offering makes no claim that
the field is absent from the Full Offering. `detail_fields` can identify fields available through
full retrieval.

## Service-Defined Attributes and Schema

`attributes`, when present, MUST be a non-empty JSON object containing Service-defined Offering
data. An Offering that contains `attributes` MUST also contain `schema`. A Service MUST omit both
fields when it has no Service-defined attributes for the Offering.

`schema` identifies a JSON Schema Draft 2020-12 document that validates the complete `attributes`
object. It contains exactly one member, `url`, a Resource Reference. Multiple Offerings MAY share
one Attribute Schema. HTTP response metadata and the schema document itself describe the retrieved
resource; the ODP reference does not repeat a media type, version, digest, or caching metadata.

When a Terse Offering contains `attributes`, it MUST also contain `schema`. The Attribute Schema
describes the complete Full Offering attributes. The recursively omitted members of terse
`attributes` can be identified through `detail_fields`.

## Attribute Schema Retrieval and Processing

An Agent resolves `schema.url` against the Offering response URL and retrieves it with `GET`. It
SHOULD send `Accept: application/schema+json`. A successful response MUST have a `Content-Type`
whose media-type essence is `application/schema+json` and MUST contain a JSON Schema Draft 2020-12
document. A missing, malformed, differently typed, or invalid document is an unusable Attribute
Schema.

An Attribute Schema is an ordinary mutable HTTP resource. HTTP cache directives and validators are
authoritative, and the Attribute Schema fallback defined in HTTP Caching applies when the response
provides no freshness information. Neither the schema URL nor a previously retrieved schema makes
the schema immutable. An Agent revalidates or refreshes it according to ordinary HTTP caching
semantics.

The schema MUST declare the Draft 2020-12 meta-schema through `$schema`. `$id`, when present, and
references have their standard JSON Schema meanings. An Agent MUST process references needed to
interpret or validate the instance. If the schema declares a required vocabulary the Agent does not
support, the Attribute Schema is unsupported. Optional vocabularies and unknown keywords are handled
according to JSON Schema Draft 2020-12.

An Agent-oriented SDK SHOULD resolve and cache referenced schema resources and provide its caller a
locally complete schema representation. The caller MUST NOT be required to perform additional
network requests merely to interpret the returned Offering. Retrieval limits and protections apply
to the complete reference graph rather than independently granting every reference unbounded network
access.

A Service MUST validate the complete `attributes` object in a Full Offering against its Attribute
Schema. An Agent SHOULD validate Full Offering attributes before relying on them. Terse Offering
attributes are a partial view of the Full Offering instance and MUST NOT be validated as though they
were the complete instance. Every included terse value retains the type and meaning assigned by the
Attribute Schema.

An unavailable, invalid, unsupported, or non-matching Attribute Schema makes the Offering's
`attributes` uninterpretable. It does not invalidate the Offering's identity, core descriptive
fields, Price Preview, `web_url`, Collection membership, or actions. Agent-oriented SDKs SHOULD omit
uninterpretable attributes from their normalized result and report a scoped issue separately. The
SDK result shape is an implementation contract and does not add an `issues` member to the ODP wire
representation.

## Price Preview

An Offering MAY contain `price`, a discovery-time summary that helps an Agent evaluate and compare
Offerings before invoking a subsequent operation. Absence of `price` means that the Service has not
advertised a price. It MUST NOT be interpreted as free.

Every Price Preview contains a `type` discriminator. This specification defines `free`, `fixed`,
`range`, `starting_at`, `metered`, and `quote`. Monetary values MUST be non-negative decimal strings
and MUST NOT be represented as JSON numbers. `currency` is the display denomination of the summary;
it does not select a payment protocol, network, rail, or settlement asset.

| Type          | Required members                         | Meaning                                      |
| ------------- | ---------------------------------------- | -------------------------------------------- |
| `free`        | `type`                                   | No price is required.                        |
| `fixed`       | `type`, `amount`, `currency`             | One advertised display price.                |
| `range`       | `type`, `minimum`, `maximum`, `currency` | An inclusive advertised display range.       |
| `starting_at` | `type`, `amount`, `currency`             | The lowest advertised starting price.        |
| `metered`     | `type`, `amount`, `currency`, `unit`     | An advertised rate per Service-defined unit. |
| `quote`       | `type`                                   | A later operation determines the price.      |

For `range`, `minimum` MUST be less than or equal to `maximum`. A Price Preview excludes taxes,
shipping, discounts, buyer-specific terms, fees, availability, and final quote results unless the
Offering explicitly states otherwise outside the core price object.

A live MPP or x402 challenge, quote response, or other subsequent operation is authoritative for the
amount and settlement choices presented at execution time. A Price Preview MUST NOT be treated as a
payment authorization or settlement requirement. If an authoritative subsequent value differs from
the Price Preview, an Agent MUST use and present the authoritative value rather than silently
relying on the preview.

An Agent encountering an unknown Price Preview `type` treats only that `price` object as
unsupported. The Offering and its unrelated fields remain usable. This permits compatible addition
of future Price Preview discriminators.

## Actions

A Full Offering MAY contain `actions`, a non-empty array of operations that can follow discovery. An
Offering with no advertised action omits the field. A Terse Offering MUST NOT contain `actions`;
when permitted by the common representation rules it can advertise `/actions` through
`detail_fields`.

An Action describes an executable HTTP transition associated with its Offering. It does not define a
commerce workflow, payment behavior, or the domain-specific shape of the operation's successful
result. An Action has required `authentication`, `id`, and `rel` members, can contain `description`,
and contains exactly one of `http` or `openapi`. An Offering contains at most 16 Actions, and their
`id` values MUST be unique within that Offering. Action identifiers use the Local Resource
Identifier syntax and remain stable while the Action exists on that Offering.

`authentication` is `not-required`, `optional`, or `required` and has the same meanings as on an
Operation Descriptor, applied to execution of that Action at the Action target. The Action target
remains the authority for execution semantics; OpenAPI metadata is optional enrichment and is not
required to express authentication or payment behavior.

`rel` states the broad result sought from the operation. It is a lower-case token of at most 64
characters using letters, digits, and internal hyphens. This specification defines five values:

| Relation   | Meaning                                                       |
| ---------- | ------------------------------------------------------------- |
| `download` | Retrieve a downloadable representation, whether free or paid. |
| `purchase` | Complete a one-time acquisition.                              |
| `quote`    | Obtain current terms without completing an acquisition.       |
| `reserve`  | Hold or allocate a resource.                                  |
| `invoke`   | Execute an online capability and obtain its result.           |

`free` is a Price Preview type and is not an Action relation. `download` does not imply that an
Offering is free. Recurring subscription behavior is not defined by ODP 1.0. An Agent encountering
an unknown `rel` retains the Action but MUST NOT automatically select it based on an assumed
meaning. A caller can explicitly select the Action by `id`.

### Compact HTTP Target

`http` describes an operation that does not need a complete interface description. It contains a
required Resource Reference `href` and a required `method` of `GET` or `POST`. It can contain a
non-empty `request` object and a non-empty `response_content_types` array of at most eight unique
media types. Parameters, multiple request-body alternatives, complex responses, or declared security
requirements require an OpenAPI target instead.

`request` describes one optional request body. It contains at least one of `content_type` or
`schema`. `content_type` identifies the body media type. `schema` is a JSON Schema reference with a
required Resource Reference `url` and follows the retrieval, resolution, caching, vocabulary, and
narrow-failure rules defined for Attribute Schemas. The schema describes only the Action request
body. It does not describe URL, header, or cookie parameters. An Agent MUST NOT send a request body
unless the caller supplies one or the operation definition supplies a complete value.

`response_content_types` advertises media types the successful operation can return. It does not
constrain authentication, payment, redirection, Problem Details, or other non-success responses. The
live response `Content-Type` remains authoritative.

### OpenAPI Target

`openapi` identifies exactly one operation in an OpenAPI 3.1 document {{OPENAPI31}}. It contains an
optional Resource Reference `url` and a required case-sensitive `operation_id` of at most 128
Unicode code points. When `url` is absent, the Service Document MUST contain `http.openapi.url`, and
that value is used. An Action-level `url` overrides the Service-wide value. An Action is unusable if
neither reference exists. The referenced document MUST use an `openapi` version in the `3.1.x` line
and MUST contain exactly one Operation Object whose `operationId` equals `operation_id`. An Agent
MUST NOT guess an operation from a path, method, summary, description, or similar identifier when
that lookup fails or is ambiguous.

OpenAPI retrieval is anonymous. An Agent MUST NOT attach AEP credentials, payment credentials,
cookies, or authorization fields copied from the Offering request. Agents accept JSON represented as
`application/vnd.oai.openapi+json` with a `version=3.1` parameter or `application/json`; missing,
malformed, non-JSON, or other media types are rejected. Standard HTTP caching applies. The decoded
document is limited to 1,048,576 bytes, JSON depth 32, and five redirects.

An invalid Action, failed request-schema retrieval, failed OpenAPI retrieval, or unresolved
`operation_id` makes only that Action unusable. Duplicate Action IDs make every Action bearing that
ID unusable. Unrelated Actions and Offering fields remain usable. An Agent-oriented SDK exposes
these failures as scoped issues rather than rejecting the entire Offering.

Action metadata is descriptive. A live AEP, MPP, x402, or other HTTP challenge is authoritative for
access and payment. An Agent MUST NOT execute an action whose request, authorization, payment, or
security consequences it cannot determine.

Payment protection and Action meaning are independent. Paying to retrieve an ODP Offering grants
access to that Offering representation and MUST NOT be interpreted as acquiring the Offering. An
Agent invokes the separate Action target in its current authentication context and follows live AEP
and payment challenges according to the composition rules in this document. A successful Action
response is interpreted according to the compact metadata or OpenAPI operation, not as an ODP
Offering response unless that operation explicitly returns one.

## Offering Granularity

A Service chooses the granularity of its Offerings. A variant that can be independently retrieved,
quoted, reserved, acquired, or paid for SHOULD have its own Local Resource Identifier and Offering.
Attributes can describe variants that are not independently actionable. This guidance does not
define a universal variant model or require a Service to mirror its internal catalog structure.

# Extensibility Model

## Core Evolution

Agents MUST ignore additive JSON object members they do not understand unless another rule in this
document requires the containing object or capability to be rejected. Services MUST NOT use an
unknown member to change the semantics of a core member.

An Agent encountering an unknown enum or discriminator value MUST NOT substitute a known value or
invent fallback semantics. It MUST treat the smallest capability, resource, or operation whose
interpretation depends on that value as unsupported. Unrelated resources and operations remain
usable.

Security-sensitive behavior fails closed. An Agent MUST NOT execute an operation when an unknown
field or value prevents it from determining the operation's identity, authorization, payment,
request semantics, or security consequences.

## Service-Defined Offering Data

ODP defines stable envelope fields needed for discovery and link traversal. Domain-specific Offering
data belongs in the Service-defined `attributes` object. When present, its Attribute Schema MUST
identify the structure, types, and constraints of that value using JSON Schema Draft 2020-12
{{JSON-SCHEMA}}.

An Attribute Schema can be shared across multiple Offerings. The schema's titles, descriptions,
examples, and constraints help an Agent compare unfamiliar attributes without requiring the ODP core
specification to standardize every domain.

Filter identifiers are local to the operation or scope that advertises them. A small Service MAY
embed Filter Definitions in an ODP representation. A large Service MAY link to a separate, pageable
filter-definition resource. An Agent MUST interpret a filter identifier using the definition
advertised for the operation and scope in which the filter is used.

A Service Document SHOULD contain only Service-level discovery metadata and operation advertisement.
Collection-specific or high-cardinality definitions SHOULD be linked from the narrowest applicable
Collection or operation so that a Service Document remains bounded as the catalog grows.

# Filters and Sorting

## Capability Identifiers

A Filter Definition and Sort Definition contains a Service-created capability identifier. It is a
case-sensitive ASCII string of 1 through 64 characters from `ALPHA`, `DIGIT`, `.`, `_`, `~`, and
`-`. It is compared byte for byte and is not percent-decoded or Unicode-normalized.

A capability identifier is not a Local Resource Identifier and does not identify an independently
retrievable ODP resource. Its meaning is scoped by the Service Origin, operation, capability source,
definition kind, and identifier. The same spelling can have different meanings at different Services
or scopes. Capability advertisement, inheritance, and conflict rules define the effective scope in
which a reference is resolved.

## Filter Value Model

A Filter Definition maps each Offering to a set containing zero or more scalar values of one
declared type. The mapping can use core Offering metadata, Service-defined attributes, computed
catalog data, an external index, or another Service implementation detail. It does not expose a
storage path and need not correspond to a serialized Offering field.

The core filter types and their wire values are:

| Type        | Wire value                                                                   |
| ----------- | ---------------------------------------------------------------------------- |
| `string`    | JSON string.                                                                 |
| `boolean`   | JSON Boolean.                                                                |
| `integer`   | JSON integer.                                                                |
| `number`    | JSON number.                                                                 |
| `decimal`   | Base-10 JSON string without an exponent.                                     |
| `date`      | RFC 3339 `full-date` JSON string.                                            |
| `date-time` | RFC 3339 `date-time` JSON string identifying an instant on the UTC timeline. |

A decimal value matches `-?(0|[1-9][0-9]*)(\\.[0-9]+)?`. Decimal equality and ordering are numeric,
not lexical, so `1.0` and `1.00` compare equal. Integer and number comparison is numeric. Boolean
equality follows JSON Boolean equality. Date comparison follows calendar order. Date-time equality
and ordering use the represented instant. String equality is case-sensitive Unicode scalar-value
equality; ODP performs no normalization or locale folding.

## Filter Definitions

A Filter Definition contains `id`, `title`, `description`, `type`, and `operators`. `title` is a
non-empty string of no more than 128 Unicode code points. `description` is a non-empty string of no
more than 1024 Unicode code points. `operators` is a non-empty array of unique supported core
operators. A numeric Filter Definition MAY contain `unit`; other types MUST omit it. A definition
that supports value-count refinement contains `refinable` with the value `true`; otherwise it omits
`refinable`. A refinable definition MUST advertise `eq`, `in`, or both.

Every operator advertised by a Filter Definition MUST be compatible with its type:

| Operator | Compatible types                                         |
| -------- | -------------------------------------------------------- |
| `eq`     | All core filter types.                                   |
| `in`     | All core filter types.                                   |
| `lt`     | `integer`, `number`, `decimal`, `date`, and `date-time`. |
| `lte`    | `integer`, `number`, `decimal`, `date`, and `date-time`. |
| `gt`     | `integer`, `number`, `decimal`, `date`, and `date-time`. |
| `gte`    | `integer`, `number`, `decimal`, `date`, and `date-time`. |
| `exists` | All core filter types.                                   |

## Units

A unit is an inline object whose `system` is `ucum` or `service`. A UCUM unit contains `system` and
`code`; `code` is a valid case-sensitive UCUM code as defined by {{UCUM}}. A Service-defined unit
also contains `title`, a non-empty human-readable name of no more than 128 Unicode code points. Its
code uses the capability-identifier syntax.

Every value supplied to a Filter Expression uses the unit declared by its Filter Definition, so the
request does not repeat the unit. A missing unit means that the values are categorical or
dimensionless. Agents can interpret and convert compatible UCUM values. A Service-defined unit is
meaningful only in that Service and capability scope; an Agent MUST NOT infer equivalence or
conversion from similar codes or titles. A unit is fully defined inline and does not require URL
retrieval.

## Filter Expressions

`filters` is a non-empty array of no more than 32 Filter Expressions. Each expression contains `id`,
`operator`, and `value`. `id` MUST resolve to an effective Filter Definition for the operation and
scope. The operator MUST be advertised by that definition, and the value MUST conform to the
definition's type and the following shape:

| Operator                       | Request value                                                             |
| ------------------------------ | ------------------------------------------------------------------------- |
| `eq`, `lt`, `lte`, `gt`, `gte` | One scalar of the Filter Definition's type.                               |
| `in`                           | An array of 1 through 100 unique scalars of the Filter Definition's type. |
| `exists`                       | A JSON Boolean.                                                           |

For `eq`, an Offering matches when at least one mapped value equals the request value. For `in`, it
matches when its mapped set and the request set intersect. For a comparison operator, it matches
when at least one mapped value satisfies the comparison. For `exists: true`, it matches when the
mapped set is non-empty; for `exists: false`, it matches when that set is empty.

Every Filter Expression in one request combines with logical AND. The same identifier can appear
more than once, which permits bounded ranges such as `gte` and `lte`. `in` expresses logical OR
among accepted values for one Filter Definition. ODP version 1.0 defines no general Boolean
expression tree, negative operator, substring operator, or regular-expression operator.

An unknown identifier, unadvertised or incompatible operator, invalid value, excessive expression
count, or excessive `in` cardinality produces an `INVALID_REQUEST` problem.

## Refinements

`refinements` in an Offering-search request is a non-empty array of at most 16 unique capability
identifiers. Every identifier MUST resolve to an effective Filter Definition whose `refinable`
member is `true`. An unavailable, invalid, quarantined, duplicate, or non-refinable identifier
produces an `INVALID_REQUEST` problem. A Service that advertises no refinable Filter Definitions
does not implement refinement computation.

An initial Offering-search response MAY contain `refinements` only when the request contains it. The
response member is a non-empty array of at most 16 Refinement Groups. Each group contains
`filter_id` and `values`; `filter_id` MUST occur in the request and MUST be unique among the
returned groups. A Service MAY omit a requested group when it cannot produce useful values. An
omitted group does not invalidate other groups or the Offering results.

`values` contains 1 through 32 Refinement Buckets whose values are unique under the referenced
Filter Definition's equality semantics. Each bucket contains `value` and `count`. `value` MUST be a
scalar valid for the referenced Filter Definition's type. `count` is a non-negative JSON integer no
greater than 9,007,199,254,740,991. An exact count omits `count_relation`. A count known only to be
a lower bound contains `count_relation` with the value `lower_bound`. A Service MUST NOT report an
estimate as exact.

For one bucket, the Service evaluates the original Collection constraint, query, access context, and
every Filter Expression whose identifier differs from the group's `filter_id`. It then applies the
bucket value to the referenced Filter Definition using its equality semantics. `count` is the number
of distinct matching Offerings. Removing same-filter expressions makes alternative values useful for
navigation while retaining every independent constraint. Sorting and page limits do not affect the
count.

Refinement values are contextual suggestions, not a complete enumeration of a Filter Definition's
domain and not another capability source. An Agent resolves `filter_id` through the effective
capability catalog and interprets every bucket using that definition's type and unit. ODP does not
define total-result counts; a bucket count applies only to that candidate value. An Agent-oriented
SDK SHOULD return normalized groups with their resolved Filter Definitions and scoped issues rather
than requiring its caller to join raw identifiers.

## Sort Definitions

A Sort Definition advertises one complete ordering recipe that the Service can execute. It contains
`id`, `title`, `description`, and `keys`. `title` and `description` use the Filter Definition string
limits. `keys` is an array of 1 through 3 Sort Keys. Each Sort Key contains `filter_id`,
`direction`, and `missing`. Every `filter_id` MUST be distinct and resolve to an effective Filter
Definition in the same operation and scope. `direction` is `ascending` or `descending`; `missing` is
`first` or `last`.

For a Sort Key whose Filter Definition maps an Offering to multiple values, `ascending` selects the
minimum value and `descending` selects the maximum value before ordering Offerings. Numeric,
decimal, date, and date-time values use the comparison semantics defined for filters. The Service
defines type-appropriate string collation and MUST describe non-obvious collation in the Sort
Definition. The advertised key sequence, directions, and missing-value placement are fixed. The
Agent selects a recipe through the search request's `sort` member and MUST NOT add, remove, reverse,
or reorder its keys.

The Service MUST append Offering `id` as the final ascending tie-breaker after all advertised keys.
The resulting order is subject to the common stable-pagination contract. An absent `sort` selects
the Service's preferred ordering and does not require a Sort Definition. An unknown or unavailable
Sort Definition identifier produces an `INVALID_REQUEST` problem.

## Search Capability Advertisement

`search_capabilities` is an object that contains at least one of `filters` or `sorts`. A Service
Document advertises Service-wide capabilities. A Full Collection Representation advertises
capabilities specific to searches whose request explicitly names that Collection. The field MUST NOT
appear unless the Service advertises `search-offerings`.

`filters` and `sorts` are independent capability sources. Each source contains exactly one of
`inline` or `linked`. `inline` is a non-empty array containing no more than 32 Filter Definitions or
16 Sort Definitions, according to the source. `linked` is an object containing `href`, a same-origin
Resource Reference to the first page of the applicable definition sequence. A source with no
definitions is omitted rather than represented by an empty array.

A linked source is retrieved with `GET` and uses `application/odp+json`. The response is a standard
page envelope whose `items` contain only the applicable definition kind and whose `next` links obey
the common continuation contract. A page contains no more than 100 definitions, and a complete
linked source contains no more than 16 pages. The linked operation can enforce access policy through
live HTTP challenges. It follows the common `Accept-Language`, `Content-Language`, `Vary`,
validator, redirect, response-limit, and caching rules. The advertisement does not contain a
redundant pagination flag; only `next` indicates another page.

Each inline or complete linked source is atomic. An Agent MUST retrieve and validate every page,
enforce source uniqueness and bounds, and only then expose definitions from that source. It MUST NOT
expose an earlier page while later pages remain unresolved. A failed or invalid source is omitted
from the normalized capability catalog and reported as a scoped issue. Once a linked source cannot
fit within the applicable effective-catalog bound, the Agent MUST stop retrieving that source and
discard it. If page 16 contains `next`, the Agent MUST NOT retrieve page 17 and MUST discard the
source. Failure of a Collection-specific source does not invalidate a valid Service-wide source, and
capability failure does not prevent text-only Offering search.

## Effective Search Capabilities

An Offering search without `collection_id` uses only Service-wide capabilities. A search with
`collection_id` uses the union of Service-wide capabilities and capabilities advertised by that
exact Collection. Ancestors, descendants, and other Collections do not contribute definitions.
`include_descendants` changes the Offering membership scope but does not change capability
inheritance.

The effective catalog contains at most 1,024 Filter Definitions and 128 Sort Definitions after
merging its sources. The Service-wide source is applied before the selected-Collection source.
Exceeding either limit makes the source that causes the overflow invalid; an Agent preserves earlier
valid sources and reports a scoped issue. SDKs SHOULD retain and index the normalized catalog
programmatically rather than placing every definition into an Agent's language model context.

A conforming Service MUST NOT publish the same Filter Definition identifier or Sort Definition
identifier in two effective sources, even when their serialized definitions are equal. An Agent
quarantines each cross-source duplicate identifier rather than selecting an override. It also
quarantines every Sort Definition that references a missing, invalid, or quarantined Filter
Definition. Unrelated definitions remain usable. A request using a quarantined or otherwise
unavailable identifier produces an `INVALID_REQUEST` problem.

An Agent-oriented SDK SHOULD expose one normalized effective capability catalog containing valid
Filter Definitions and resolved Sort Definitions, plus scoped issues. Callers need not process raw
capability pages, merge scopes, detect conflicts, or resolve Sort Definition references.

# Composition Boundaries

ODP describes resources and references that lead to subsequent operations. It does not duplicate the
semantics of those operations.

A Service MAY make ODP resources public, require AEP {{AEP}} enrollment before some or all ODP
operations, require MPP {{MPP}} or x402 {{X402}} payment, or combine these protocols in a
Service-selected order. Capability metadata is descriptive. Live HTTP authentication and payment
challenges are authoritative for the credentials, payment requirements, and retry mechanics of the
request being made. An advertised authentication requirement does not replace those challenges.

The following signals belong to their defining protocols and are not redefined by ODP:

| Protocol | Live signal                                                              |
| -------- | ------------------------------------------------------------------------ |
| AEP      | `401 Unauthorized` with an `AEP` challenge in `WWW-Authenticate`.        |
| MPP      | `402 Payment Required` with a `Payment` challenge in `WWW-Authenticate`. |
| x402     | `402 Payment Required` with payment requirements in `PAYMENT-REQUIRED`.  |

A Service that requires both AEP and payment for an ODP operation MUST authenticate the Agent before
processing payment. Its response to a request without acceptable AEP credentials has status 401 and
carries the AEP challenge, even if the request also lacks payment. After AEP authentication
succeeds, the Service can return the applicable live payment challenge.

An Agent begins with the requested ODP operation in its current authentication context. A valid AEP
challenge causes it to complete the AEP flow and retry the same operation with an AEP credential.
When payment can follow, the Agent SHOULD use the dedicated `AEP-Authorization` field defined by AEP
so that `Authorization` remains available for an MPP credential. The Agent fulfills payment only
after the authenticated retry returns a live payment challenge. It then retries with the AEP
credential and either the MPP `Authorization: Payment` credential or the x402 `PAYMENT-SIGNATURE`
field, as defined by the selected payment protocol.

This sequence does not require AEP where the Service does not require enrollment. A public operation
can succeed immediately, and a payment-only operation can return `402 Payment Required` directly.
Each retry remains subject to the credential handling, request binding, redirect, replay, and error
rules of the protocol that caused it.

A successful response means that the request did not require another challenge at that point,
regardless of the Service-wide advertisement. A live challenge for an unadvertised protocol is still
authoritative. An advertised protocol without a corresponding live challenge MUST NOT cause an Agent
to enroll, authenticate, or pay speculatively.

An Agent MUST NOT infer that support for ODP implies support for AEP, MPP, x402, or any other
protocol. An Agent MUST NOT infer that support for one composition order implies support for
another.

# Errors and Limits

## Problem Details

An error generated by ODP request processing with a response body MUST use Problem Details as
defined by {{RFC9457}} and the `application/problem+json` media type. A response governed by a live
authentication or payment challenge protocol retains that protocol's body rules. The Problem Details
object MUST contain `type`, `title`, `status`, and `code`. `detail` and `instance` are optional.
`status` MUST equal the HTTP response status. `title` contains no more than 128 Unicode code points,
and `detail` contains no more than 2048 Unicode code points.

`type` is an absolute HTTPS URL under `https://offeringprotocol.org/problems/` identifying the
problem class. `code` is the stable machine-readable identifier used by Agent implementations. A
code contains 1 through 64 uppercase ASCII letters, digits, or underscores and begins with a letter.
An Agent MUST ignore unknown additive Problem Details members.

The initial core problem codes are:

| Code                     | Status | Meaning                                       |
| ------------------------ | -----: | --------------------------------------------- |
| `INVALID_REQUEST`        | 400    | Request syntax or values are invalid.         |
| `NOT_AUTHENTICATED`      | 401    | Authentication is required or invalid.        |
| `NOT_AUTHORIZED`         | 403    | The principal cannot perform the operation.   |
| `NOT_FOUND`              | 404    | The requested ODP resource does not exist.    |
| `NOT_ACCEPTABLE`         | 406    | No acceptable response representation exists. |
| `CONTINUATION_EXPIRED`   | 410    | The continuation link has expired.            |
| `REQUEST_TOO_LARGE`      | 413    | The request exceeds its resource limit.       |
| `UNSUPPORTED_MEDIA_TYPE` | 415    | The request media type is unsupported.        |
| `RATE_LIMITED`           | 429    | Request rate or quota has been exceeded.      |
| `SERVICE_UNAVAILABLE`    | 503    | The Service is temporarily unable to respond. |

Later compatible protocol revisions can define additional codes. An Agent encountering an unknown
code MUST use the HTTP status and standard Problem Details members as its fallback semantics. It
MUST NOT reinterpret an unknown code as a known one.

Live HTTP authentication and payment challenges remain authoritative. A Problem Details body does
not replace `WWW-Authenticate`, MPP, x402, AEP, or another challenge header, and an Agent MUST
preserve those headers for the applicable protocol handler.

## Invalid Parameters

An `INVALID_REQUEST` problem MAY contain `invalid_params`, a non-empty array of parameter failures.
Each entry contains `in`, `name`, and `reason`. `in` is one of `query`, `body`, `header`, or `path`.
For a body member, `name` is a JSON Pointer as defined by {{RFC6901}}. For another location, `name`
is a non-empty parameter or header name. `name` contains no more than 256 Unicode code points, and
`reason` is a non-empty concise explanation of no more than 1024 Unicode code points. The array
contains no more than 32 entries. An Agent MUST NOT parse `reason` to determine recovery behavior.

## Agent Error Results

An Agent-oriented SDK SHOULD map an operation failure to a typed error containing at least `code`,
`message`, and `retryable`. It can also expose retry timing and structured invalid parameters. A
failed requested operation is an error, not a partial-result issue. A scoped enrichment failure that
does not invalidate the requested ODP resource, such as an unavailable Attribute Schema, remains an
issue under the applicable SDK result contract.

## Resource Limits

Limits apply after HTTP content codings are decoded and before a representation is exposed to an
Agent caller. JSON depth is measured from the top-level value. A Service MUST produce documents
within the applicable limits, and an Agent MUST stop reading a body when it exceeds its applicable
byte limit.

| Resource                                   | Limit           |
| ------------------------------------------ | --------------: |
| ODP request body                           | 65,536 bytes    |
| Individual Collection or Offering response | 524,288 bytes   |
| List, search, or Filter Definition page    | 524,288 bytes   |
| Problem Details response                   | 16,384 bytes    |
| JSON nesting depth except Service Document | 16              |
| Service Document                           | 65,536 bytes    |
| Service Document nesting depth             | 8               |
| Items per page                             | 100             |
| Pages per linked capability source         | 16              |
| One Attribute Schema document              | 262,144 bytes   |
| Complete Attribute Schema reference graph  | 1,048,576 bytes |
| One OpenAPI Action document                | 1,048,576 bytes |
| Distinct documents in one schema graph     | 16              |
| Attribute Schema reference depth           | 8               |
| Redirects per retrieved resource           | 5               |

The more specific Service Document, field, relationship, and pagination limits elsewhere in this
document continue to apply. A Service MAY return fewer page items than requested to remain within
the page limit. Domain-specific attribute arrays are bounded by their Attribute Schema and the
overall byte and depth limits rather than by a universal element count.

Every redirect target for an ODP resource, JSON Schema resource, or OpenAPI Action document MUST
retain the scheme, host, and effective port of the preceding request. An Agent MUST reject redirect
loops, transport security downgrades, and a sixth redirect. A cross-origin Resource Reference can
initiate a request to its explicit origin; that resource cannot use redirects to transfer the
request to another origin.

## Limit Failures

A receiver MUST NOT truncate and expose partial JSON, a partial schema, a partial string, or a
partial array. It rejects the affected document before exposing any of that document's contents.
Valid items yielded from earlier pages remain valid, but automatic pagination stops at the failing
page. An Agent-oriented SDK reports a local `RESPONSE_LIMIT_EXCEEDED` error for the failed
operation.

An Attribute Schema limit failure makes the corresponding attributes uninterpretable. The SDK omits
those attributes from its normalized result and reports a scoped issue; unrelated Offering fields
remain usable. A Service receiving an oversized ODP request returns `413 Content Too Large` with
`REQUEST_TOO_LARGE` Problem Details.

## Rate Limits and Retries

A `429 Too Many Requests` response MUST include `Retry-After`. A `503 Service Unavailable` response
SHOULD include it. An Agent-oriented SDK SHOULD support bounded automatic retry for these statuses.
The default policy performs at most three retries and spends at most 30 seconds waiting across the
operation. It honors `Retry-After` when doing so does not exceed that elapsed-time limit; otherwise
it returns the typed error without waiting. When `Retry-After` is absent on `503`, the SDK uses
bounded exponential backoff with jitter.

ODP list, search, and retrieval operations are read-only at the application layer and can be retried
under this policy. An SDK MUST NOT automatically restart an expired continuation or retry an
authentication, authorization, validation, or other non-transient failure.

## Compatibility of Errors

The core evolution rules apply to successful and unsuccessful documents. Unknown additive members
are ignored. Unknown Problem Details codes fall back to HTTP status semantics. Unknown
discriminators disable only the smallest dependent capability, and security-sensitive ambiguity
fails closed. A major-version mismatch rejects an ODP document; same-major minor versions use the
compatibility rules defined in Protocol Versioning.

# Conformance

An implementation claims conformance separately for the Agent and Service roles. ODP defines one
required baseline for each role. It does not define named conformance levels, profiles, or a
`minimum` capability.

## Service Baseline

A conformant ODP Service:

1. publishes a valid, publicly retrievable Service Document at `/.well-known/odp`;
2. advertises and implements `list-offerings` and `get-offering` using its advertised endpoint base;
3. implements the shared versioning, media type, representation, pagination, localization, caching,
   error, limit, redirect, and security requirements applicable to those operations; and
4. satisfies every Service requirement for each additional operation, protocol, search feature, or
   per-resource feature it advertises or returns.

The Offering sequence can be empty. A Full Offering still requires only `odp_version`, `id`, and
`name`; Actions, prices, attributes, schemas, Collection membership, and other optional fields do
not become required by baseline conformance.

## Agent Baseline

A conformant ODP Agent:

1. retrieves and validates the Service Document;
2. invokes `list-offerings`, follows its continuation sequence, and processes Terse and Full
   Offering representations;
3. invokes `get-offering` and processes a Full Offering; and
4. implements the shared versioning, media type, representation, pagination, localization, caching,
   error, limit, redirect, compatibility, and security requirements applicable to those operations.

An Agent can omit Collections, search, filters, sorting, refinements, Attribute Schema resolution,
Actions, and external protocol composition. It MUST ignore or narrowly isolate unsupported optional
data according to this document and MUST NOT claim support for behavior it does not implement.

## Runtime Advertisement and Evidence

ODP defines no generic `capabilities` member and no secondary runtime conformance manifest. Runtime
support is advertised through the singular `odp_version`, `operations`, `protocols`,
`search_capabilities`, `mcp`, and applicable per-resource members such as `schema` and `actions`. An
implementation MUST NOT add a parallel claim that can contradict those authoritative fields.

A conformance harness can generate release evidence identifying the implementation name and version,
role, singular ODP version tested, vector revision, suites executed, and passed, failed, and skipped
results. Such a report describes test evidence for one software release. It is not an ODP wire
document, is not retrieved during discovery, and does not override runtime advertisement or
normative requirements.

Directory behavior is outside ODP conformance. Examples, guides, schemas, and test vectors support
implementation and testing; they do not override normative Internet-Draft prose.

# IANA Considerations

## Media Type Registration

This document requests registration of the following media type in the Media Types registry
according to {{RFC6838}}:

| Field                                            | Value                                                                  |
| ------------------------------------------------ | ---------------------------------------------------------------------- |
| Type name                                        | `application`                                                          |
| Subtype name                                     | `odp+json`                                                             |
| Required parameters                              | None                                                                   |
| Optional parameters                              | None                                                                   |
| Encoding considerations                          | Binary; the representation is a JSON document encoded in UTF-8.        |
| Security considerations                          | See the Security Considerations section of this document.              |
| Interoperability considerations                  | The `odp_version` member identifies the protocol compatibility family. |
| Published specification                          | This document.                                                         |
| Applications that use this media type            | Agents and Services implementing ODP.                                  |
| Fragment identifier considerations               | None; ODP Resource References prohibit fragments.                      |
| Additional information                           | None.                                                                  |
| Person and email address for further information | IETF, `iesg@ietf.org`.                                                 |
| Intended usage                                   | COMMON                                                                 |
| Restrictions on usage                            | None.                                                                  |
| Author                                           | IETF                                                                   |
| Change controller                                | IETF                                                                   |

## Well-Known URI Registration

This document requests the following registration in the Well-Known URIs registry defined by
{{RFC8615}}:

URI suffix
: `odp`

Change controller
: IETF

Specification document
: This document

Related information
: None

# Security Considerations

## Untrusted Content and Agent Control

Every ODP representation, string, schema, OpenAPI document, URL, cursor, and Action is untrusted
network input. An Agent MUST validate a representation before using its Service-defined data or
following its references. Names, descriptions, keywords, schema annotations, examples, and other
human-readable content are data; they MUST NOT supersede caller intent, implementation policy,
protocol requirements, or higher-priority Agent instructions.

An implementation MUST safely encode untrusted strings for its output context. It MUST NOT interpret
terminal control sequences, markup, code fragments, schema keywords, OpenAPI extensions, or media
type parameters as executable instructions. JSON Schema formats and regular expressions can consume
unbounded computation in some engines. Agents MUST apply documented time, memory, recursion, and
evaluation limits and MUST NOT load executable code to process a schema or OpenAPI extension.

## Network Request and SSRF Protection

Resource References can identify a different origin only through an explicit absolute HTTPS URL.
Cross-origin support does not grant unrestricted network access. Before each connection, an Agent
MUST resolve the target host and reject every destination address that is loopback, private-use,
link-local, multicast, unspecified, reserved, documentation-only, or otherwise non-public according
to the IANA special-purpose address registries described by {{RFC6890}}. If a resolution returns
both public and non-public addresses, the Agent MUST reject the target rather than select one
result.

The Agent MUST verify that the connected peer address is one of the public addresses it validated
for that request. It MUST repeat resolution and validation for every new connection, retry, and
redirect to prevent DNS rebinding and time-of-check/time-of-use substitution. The same policy
applies when a proxy or custom resolver performs the connection; an implementation MUST NOT use
either to bypass destination policy.

The local-development HTTP exception applies only when local development is explicitly enabled and
the URL host is syntactically `localhost`, `127.0.0.1`, or `[::1]`. A DNS name that resolves to a
loopback or other non-public address does not qualify. Production defaults MUST keep local-network
access disabled. Implementations MAY impose stricter port, domain, origin, network, or enterprise
egress allowlists.

Every redirect remains limited to the preceding request's origin. A cross-origin Resource Reference
can initiate an independently validated request to its explicit origin, but neither a redirect nor a
DNS change can transfer that request to another origin or a non-public destination.

## Credential and Payment Isolation

An Agent applies origin and credential policy independently to every request. Retrieval of a JSON
Schema, OpenAPI document, or other supporting metadata is anonymous. Such a request MUST NOT contain
cookies, AEP credentials, payment credentials, caller authorization fields, or secrets copied from
the referring request.

An Agent MUST NOT copy a credential, enrollment artifact, payment proof, cookie, or authorization
field to another origin solely because an ODP representation links there. A cross-origin Action
begins without credentials belonging to the Offering Service. Credentials for the Action target can
be obtained or sent only under the target origin's applicable protocol and live challenge rules.
Redirect processing strips all sensitive fields before any separately authorized request begins.

An advertised protocol, Price Preview, Action relation, schema annotation, or OpenAPI security
declaration is not authorization to enroll, authenticate, or pay. A live challenge remains
authoritative for protocol mechanics but does not override caller approval, spend limits, accepted
assets, destination policy, or other payment policy. An Agent MUST present a changed authoritative
amount or settlement choice to its policy layer rather than silently relying on discovery metadata.

## Action Safety

Discovering, parsing, validating, or resolving an Action MUST NOT invoke its target. An Agent
invokes an Action only after a caller explicitly selects its `id` and supplies or approves the
required inputs. Unknown relations are never selected automatically. Implementations MUST NOT
prefetch an Action target as an optimization; retrieving a separately identified request schema or
OpenAPI document does not invoke the Action.

Services MUST implement a compact `GET` Action with safe HTTP semantics as defined by {{RFC9110}}.
An Agent MUST NOT automatically retry a state-changing Action after an ambiguous outcome unless the
operation defines an applicable idempotency mechanism and the retry preserves it. AEP, MPP, and x402
challenge-response retries remain governed by their defining protocols and the exact request
binding.

## MCP Endpoint Safety

An advertised MCP Endpoint is an untrusted network destination. A client that elects to connect MUST
apply the Resource Reference, destination-address, redirect, and credential-isolation requirements
to the resolved endpoint. A cross-origin MCP Endpoint starts without credentials belonging to the
ODP Service Origin. The client follows MCP's current transport and authorization requirements and
MUST NOT infer authentication state, supported capabilities, or safe tool behavior from the ODP
descriptor.

## Resource Exhaustion and Abuse

Implementations MUST enforce the decoded-size, nesting-depth, schema-graph, page, redirect, retry,
and elapsed-time limits in this document before exposing a result. Compression does not increase a
limit. A receiver fails closed when a complete document cannot be obtained within its bounds and
never treats a truncated document as valid.

Agents MUST bound concurrent Service, page, schema, OpenAPI, and Action-related work. Cursors and
Service-defined identifiers are untrusted and provide no authorization. Services SHOULD apply
request-rate, query-complexity, and concurrency controls without exposing private catalog existence
through distinguishable errors.

## Cache Poisoning and Staleness

An Agent MUST honor `Cache-Control`, `Vary`, validators, authorization context, and the cache rules
in this document. Cache entries are scoped by the effective request URL, method, representation and
localization inputs, and authentication context required by HTTP. A response obtained in an
authenticated or private context MUST NOT be reused as a public response. Validators from one URL or
origin MUST NOT validate a representation from another.

Cached discovery metadata, schemas, and OpenAPI documents can become stale or maliciously
inconsistent. They never authorize access, payment, or Action execution. Live responses and current
resource state remain authoritative, and a contradiction triggers narrow failure or revalidation
rather than merging fields from conflicting representations.

# Privacy Considerations

Discovery requests can reveal user interests, intended purchases, location constraints, or business
plans. Agents SHOULD minimize disclosed query data and avoid sending user-specific context that is
not needed for the operation.

Cross-origin schema and OpenAPI retrieval discloses the Agent's network address, timing, and
interest in the referring Service or Offering to another operator. Agents SHOULD retrieve only
supporting resources needed for the caller's operation, avoid eager resolution of every advertised
Action, and apply privacy-preserving network policy where appropriate. Sensitive values MUST NOT be
placed in Resource Reference query strings, logs, telemetry, cache keys visible to unrelated
tenants, or Problem Details intended for another party.

Services SHOULD minimize data returned in Terse Representations and apply access controls before
returning sensitive Offering attributes. Directories SHOULD limit indexed data to public Service
metadata and document their retention and refresh policies.

`auth_expands` reveals only that authentication can expand the current result. A Service MUST NOT
use `detail_fields`, result counts, identifiers, refinement counts, errors, timing differences, or
other metadata to disclose the nature or quantity of protected content to a principal that is not
permitted to learn it.

--- back

# Acknowledgements

The protocol design is informed by practical requirements from agent-native commerce, service
discovery, and large catalog systems.
