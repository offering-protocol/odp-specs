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

## Adapter Contract

The harness owns vector discovery, role and suite selection, adapter orchestration, aggregation, and
report generation. An implementation supplies an executable adapter that reads one JSON object per
line from standard input and writes one JSON object per line to standard output. The executable and
its arguments follow `--` on the harness command line, so no shell command string is evaluated.

Each request follows [`adapter-request.schema.json`](./adapter-request.schema.json) and contains one
case with its vector metadata, selected role, and sequence number. Each response follows
[`adapter-response.schema.json`](./adapter-response.schema.json) and returns the same sequence
number with `passed`, `failed`, or `skipped`. Responses can be returned in any order. Every request
must receive exactly one response. Adapter diagnostics belong on standard error; any standard-error
output is forwarded by the harness. A malformed response, missing or duplicate sequence, or nonzero
adapter exit is a harness failure.

The status describes whether the implementation produced the vector's expected outcome. It does not
repeat the input's `valid` or `expected` member. Implementations remain responsible for executing
the real public behavior represented by each case. A failed response can include `message`; the
harness writes the vector identifier, case name, and message to standard error.

Run a Service adapter against every applicable suite:

```sh
ruby ietf/scripts/run_conformance.rb \
  --role service \
  --implementation-name example-service \
  --implementation-version 1.0.0 \
  --output conformance-report.json \
  -- ./path/to/service-adapter
```

Repeat `--suite CATEGORY` to select explicit categories. Without it, the harness selects every
indexed vector applicable to the role. A report is written after a complete, valid adapter exchange.
The command exits 0 when no case failed, 1 when cases failed, and nonzero without a report when the
harness or adapter contract fails.

[`fixture-adapter.rb`](./fixture-adapter.rb) exercises only the process contract in repository
self-tests. It is not an ODP implementation and provides no conformance evidence.

Passing support artifacts does not override normative prose. A contradiction is a specification
defect and must be resolved across all affected artifacts.
