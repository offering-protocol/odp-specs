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
  RFC6454:
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
continues through links advertised by that document and subsequent ODP representations.

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
* link-driven navigation and search of Collections and Offerings;
* stable descriptive envelopes for Services, Collections, and Offerings;
* Service-defined structured Offering attributes described by JSON Schema;
* discovery of deterministic search terms, filters, and pagination capabilities;
* terse representations for result sets and full representations for inspection;
* links from discovery resources to browser experiences and subsequent machine operations; and
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
: The JSON representation published at `/.well-known/odp`. It describes the Service and links to the
  ODP capabilities that the Service exposes.

Collection
: An optional, Service-defined grouping used to navigate or constrain Offerings. Collections can be
  hierarchical, overlapping, or independent and do not impose a universal taxonomy.

Offering
: A discoverable description of something the Service makes available. An Offering can describe a
  free or paid item, a physical or digital good, a scheduled resource, a subscription, a rental, or
  another Service-defined opportunity.

Terse Representation
: A result-oriented representation containing the fields needed to identify, summarize, and follow a
  resource link.

Full Representation
: A resource representation containing the complete ODP description available to the Agent under the
  current access policy.

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
: An origin-relative absolute-path reference or an absolute URL that locates an ODP resource or a
  browser representation. A Resource Reference does not define Resource Identity.

Subsequent Operation
: An operation linked from an ODP resource whose semantics can be defined by ODP, AEP, MPP, x402, or
  another protocol.

# Roles

## Agent Role

An Agent consumes Service documents and advertised ODP resources. It selects capabilities from
advertised links, interprets Service-defined attributes using the applicable Attribute Schema, and
honors live HTTP authentication and payment challenges.

An Agent MUST NOT assume that an unadvertised ODP capability exists. An Agent MUST NOT construct
capability paths when the applicable representation provides a link. An Agent MUST treat content
received from a directory as discovery metadata rather than authoritative Offering data.

## Service Role

A Service publishes its Service document and serves the ODP resources to which it links. The Service
is authoritative for its Collections, Offerings, Attribute Schemas, filters, access policy, and
subsequent-operation links.

A Service MUST NOT advertise an ODP capability that it does not support. A Service MUST keep links
and capability metadata consistent with the behavior available to the Agent under the applicable
access policy.

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
and managed by the Service. ODP does not prescribe the Service's identifier-generation algorithm. A
Service MAY use an existing database key, UUID, SKU, URI-shaped value, or another identifier that
satisfies this section.

A Local Resource Identifier MUST contain between 1 and 255 Unicode code points. It MUST NOT contain
a control character or an unpaired surrogate. A Service MUST keep the identifier stable for the
resource's lifetime and MUST NOT assign it to another resource in the same resource-type namespace.

Collections and Offerings have separate identifier namespaces. The same Local Resource Identifier
MAY identify one Collection and one Offering at a Service. It MUST NOT identify two Collections or
two Offerings at that Service.

Agents MUST treat a Local Resource Identifier as opaque. Comparison is exact and case-sensitive
after JSON string decoding. Agents MUST NOT trim, case fold, Unicode-normalize, URL-decode, parse,
or infer semantics from an identifier.

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

Fields defined as Resource References, including `href` and `web_url`, MUST contain one of:

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
the path of the representation containing it. This rule makes `/odp/offerings/123` resolve to the
same URL whether it appears in a Service Document, Collection, search result, or Offering.

Following a cross-origin reference does not change the Service Origin or Resource Identity of the
referring ODP resource. An Agent MUST apply origin and credential policy independently to the
resolved target as required by the Security Considerations.

# Discovery Architecture

## Service Discovery

An Agent can begin with a known Service origin or obtain candidate Service origins from a directory
or another source. When a directory is used, the result of the first stage is a set of candidate
Services. The result is not a cross-Service Offering search result.

## Service Inspection

An Agent retrieves the Service document from `/.well-known/odp` at the Service origin. The Service
document advertises the ODP operations available to that Agent. The Agent follows those advertised
links to search or list Collections, search or list Offerings, retrieve full representations, and
obtain supporting definitions.

The well-known location establishes only the Service document location. Other ODP paths are not
fixed by this document and MUST be discovered from links.

## Catalog Discovery

Collections are optional navigation resources. A Service can expose Offering search without
Collections, Collection search without a hierarchy, or both. An Offering can belong to zero, one, or
multiple Collections.

List and search operations SHOULD return Terse Representations. Resource retrieval SHOULD return a
Full Representation. A Terse Representation MUST contain a link through which the Agent can obtain
the corresponding Full Representation when one is available.

Collections and Offerings MAY include a `web_url` link for a human-facing browser experience. The
browser representation is informative for Agent operation and does not replace the machine-readable
ODP resource.

# Extensibility Model

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

A Service Document SHOULD contain only Service-level discovery metadata and capability links.
Collection-specific or high-cardinality definitions SHOULD be linked from the narrowest applicable
Collection or operation so that a Service Document remains bounded as the catalog grows.

# Composition Boundaries

ODP describes resources and the links that lead to subsequent operations. It does not duplicate the
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

Directory behavior is outside ODP conformance. Examples, guides, schemas, registries, and test
vectors support implementation and testing; they do not override normative Internet-Draft prose.

# IANA Considerations

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
