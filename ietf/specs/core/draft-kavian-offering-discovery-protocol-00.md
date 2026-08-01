---
title: The Offering Discovery Protocol
abbrev: ODP
docname: draft-kavian-offering-discovery-protocol-00
date: 2026-08-01
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
  RFC6901:
  RFC2119:
  RFC8174:
  RFC8259:
  RFC8615:
  RFC9110:

informative:
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

The key words **MUST**, **MUST NOT**, **REQUIRED**, **SHALL**, **SHALL NOT**, **SHOULD**, **SHOULD
NOT**, **RECOMMENDED**, **NOT RECOMMENDED**, **MAY**, and **OPTIONAL** in this document are to be
interpreted as described in BCP 14 {{RFC2119}} {{RFC8174}} when, and only when, they appear in all
capitals, as shown here.

# Scope

ODP defines:

* discovery of a Service's ODP capabilities through a well-known Service document;
* deterministic navigation and search of Collections and Offerings;
* stable descriptive envelopes for Services, Collections, and Offerings;
* Service-defined structured Offering attributes described by JSON Schema;
* discovery of deterministic search terms, filters, and pagination capabilities;
* terse representations for result sets and full representations for inspection;
* optional links from discovery resources to browser experiences and subsequent operations; and
* Agent and Service conformance requirements.

ODP is applicable whether access is public or subject to authentication, enrollment, payment, or
another policy enforced by the Service.

# Non-Goals

ODP does not define:

* a universal taxonomy or rigid domain model for products and services;
* a protocol for enrollment, authentication, payment, checkout, tax calculation, shipping, pickup,
  fulfillment, or delivery;
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

Fields defined as Resource References, including `web_url` and subsequent-operation `href` values,
MUST contain one of:

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
`operations`, and `http`. It MAY contain `keywords`. It MUST NOT contain a self-asserted Service
identifier or `web_url`.

`name` is a non-empty string of at most 128 Unicode code points. `description` is a non-empty string
of at most 1024 Unicode code points. `keywords` is an array of at most 32 non-empty freeform
strings, each at most 64 Unicode code points and collectively at most 1024 Unicode code points. A
Service SHOULD omit `keywords` when it has none. Keywords do not draw from a protocol-defined
vocabulary.

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

`http` MUST be an object containing exactly one core member, `endpoint_base`. Its value MUST be an
origin-relative absolute-path reference beginning with exactly one `/`, MUST NOT contain a query or
fragment, and MUST contain no more than 2048 ASCII characters. The value MAY end in `/`.

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

`operations` MUST be an object containing `supported`. `supported` MUST be a non-empty array of no
more than 32 unique operation identifiers from the preceding table. An Agent MUST NOT invoke an ODP
operation that the Service Document does not advertise.

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
one hour for Filter Definitions, and 24 hours for Attribute Schemas. Each resource class MUST be
configurable independently. A fallback does not override `Cache-Control`, `Expires`, validators, or
other HTTP caching semantics.

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
data belongs in a Service-defined `attributes` value. The applicable Attribute Schema MUST identify
the structure, types, and constraints of that value using JSON Schema Draft 2020-12 {{JSON-SCHEMA}}.

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

# Composition Boundaries

ODP describes resources and references that lead to subsequent operations. It does not duplicate the
semantics of those operations.

A Service MAY make ODP resources public, require AEP enrollment before some or all ODP operations,
require MPP or x402 payment, or combine these protocols in a Service-selected order. Capability
metadata is descriptive. Live HTTP authentication and payment challenges are authoritative for the
request being made.

An Agent MUST NOT infer that support for ODP implies support for AEP, MPP, x402, or any other
protocol. An Agent MUST NOT infer that support for one composition order implies support for
another.

# Conformance

An implementation claims conformance by role.

An ODP Agent conforms to this document when it satisfies every requirement designated for an Agent
for each capability it implements. An Agent is not required to implement an optional capability, but
it MUST NOT claim support for a capability it does not implement.

An ODP Service conforms to this document when it satisfies every requirement designated for a
Service, publishes a valid Service Document, and correctly implements each capability it advertises.
A Service is not required to advertise every optional ODP capability.

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

ODP representations are untrusted network input. Implementations MUST enforce response-size,
nesting-depth, pagination, redirect, and request-time limits appropriate to their environment.
Implementations MUST validate representations before acting on links or Service-defined data.

An Agent MUST apply origin and credential policy independently to every followed link. It MUST NOT
forward credentials, enrollment artifacts, payment proofs, or other secrets to a different origin
solely because an ODP representation links to that origin.

Service-defined schemas and text can attempt to influence an Agent's behavior. An Agent MUST treat
them as data, not as instructions that supersede user intent, implementation policy, or protocol
requirements.

Cached discovery metadata can become stale. An Agent MUST treat the Service as authoritative and
MUST honor the Service's live responses, authentication challenges, payment challenges, and current
resource state.

# Privacy Considerations

Discovery requests can reveal user interests, intended purchases, location constraints, or business
plans. Agents SHOULD minimize disclosed query data and avoid sending user-specific context that is
not needed for the operation.

Services SHOULD minimize data returned in Terse Representations and apply access controls before
returning sensitive Offering attributes. Directories SHOULD limit indexed data to public Service
metadata and document their retention and refresh policies.

--- back

# Acknowledgements

The protocol design is informed by practical requirements from agent-native commerce, service
discovery, and large catalog systems.
