# Conformance

ODP defines one required baseline for each protocol role. It does not define named conformance
levels, a `minimum` capability, a generic runtime capability list, or a secondary conformance
manifest.

A conformant Service publishes `/.well-known/odp` and implements `list-offerings` and
`get-offering`. A conformant Agent consumes that baseline. Additional operations and features are
optional and become conformance obligations when an implementation advertises, returns, or claims
them.

Runtime support is advertised through the Service Document and applicable resource fields. The
offline harness generates release evidence with:

- implementation name and version;
- tested role;
- singular ODP version;
- vector revision and suites executed; and
- passed, failed, and skipped results.

Generated evidence is not an ODP wire document and is not used during discovery. The harness and
language-neutral report format are defined with the vector index. The generated report follows
[`report.schema.json`](./report.schema.json); it contains no capability manifest or runtime support
advertisement.

Passing support artifacts does not override normative prose. A contradiction is a specification
defect and must be resolved across all affected artifacts.
