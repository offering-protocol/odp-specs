# Security Policy

## Reporting a Vulnerability

Report vulnerabilities or security-sensitive specification issues privately through GitHub's private
vulnerability reporting feature for this repository or by email to:

```text
nas@inflowpay.ai
```

Alternatively, contact a repository owner directly through GitHub. Do not include credentials,
personal data, or confidential Service information unless maintainers request it through an agreed
secure channel.

## What to Report

Please report issues that could affect:

- Service document, Collection, Offering, schema, or action authenticity and integrity;
- unsafe redirect, link, or remote-schema retrieval, including server-side request forgery;
- cache poisoning, stale metadata, directory ingestion, or Service ownership verification;
- authentication and payment composition with AEP, MPP, or x402;
- authorization metadata that could cause an agent to disclose credentials to the wrong origin;
- input amplification, pagination abuse, query complexity, or denial of service;
- information disclosure, cross-Service correlation, directory privacy, or retention;
- conformance artifacts that encourage insecure implementation behavior; or
- misleading or incomplete security requirements in specification text.

## Report Contents

Include the affected specification, schema, vector, implementation, or deployed endpoint;
prerequisites; impact; a minimal reproduction when safe; and any proposed mitigation. Maintainers
will acknowledge receipt, coordinate validation and remediation privately, and disclose the issue
after a fix or appropriate mitigation is available.

## Public Discussion

Do not open a public issue for a vulnerability that could enable active exploitation, credential
disclosure, Service impersonation, unsafe network access, or directory abuse before maintainers have
coordinated a response. Security fixes may be handled privately first and followed by a public pull
request or advisory.

## Supported Versions

Security fixes are applied to the current published specification revision and the current major
release line of each official implementation. If remediation requires incompatible wire behavior,
the advisory identifies affected versions, migration requirements, and supported replacement
versions.
