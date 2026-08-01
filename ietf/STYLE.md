# ODP Specification Style

Use direct, implementation-testable requirements. Define a term before using it normatively, keep
one canonical name for each concept, and distinguish protocol requirements from examples and
guidance.

Use RFC 2119 and RFC 8174 requirement keywords only with their normative meanings. JSON uses
two-space indentation and `lower_snake_case` member names. Examples use reserved or fictional
domains and must not expose credentials or personal data. Tables, schemas, vectors, and prose must
agree.

Describe the current contract without change-history narration. Put compatibility and migration
consequences in the appropriate versioning section and pull-request description.

## Markdown Formatting

Run `make -C ietf format` from the repository root. The formatter aligns Markdown table columns and
wraps prose to 100 columns. It preserves fenced code blocks, Internet-Draft front matter, headings,
link definitions, HTML blocks, and indented code. Long URLs, inline code, headings, and table cells
may exceed 100 columns when they cannot be wrapped safely.

`make -C ietf check` includes a non-mutating formatting check. Continuous integration fails when
committed Markdown does not match the formatter output.
