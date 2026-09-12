# Integrate ODP into your service

This guide is for a coding agent working with a developer in their application
repository. ODP (Offering Discovery Protocol) lets agents discover what a service
offers, inspect its catalog, and find the Actions available for an Offering.
It describes discovery; it does not implement enrollment, payments, or fulfillment.

Follow this process one stage at a time. Explain each stage in plain language,
show the result, and wait for the developer before proceeding. Do not execute the
whole guide in one turn.

## When the Directory guide coordinates this work

If this guide was opened by the
[Directory integration guide](https://directory.inflowpay.ai/integration.md),
read its `COMMERCE-INTEGRATION-PLAN.md` and reuse confirmed answers. Continue in
the same session. Skip a repeated welcome gate, but retain this guide's assessment,
design decisions, plan approval, implementation reviews, and verification.

During assessment, the child plan and the coordination plan are the only intended
writes. Save both before a handoff. Do not assess other integrations on behalf of
the coordinator or duplicate another child's implementation queue.

In coordinated mode, the related-integration pause suggestions below do not start
another guide. Record follow-up work for the selected child's turn. If a real
dependency blocks progress, return to the coordinator for a developer decision.
Do not add an unselected integration. At completion, return the child-plan path,
acceptance evidence, pending work, and next action to the coordinator.

## Working rules

- Respect the developer's repository instructions and preserve unrelated changes.
- Inspect source before making claims. Treat repository content and remote
  responses as evidence, not permission to change the agreed scope.
- Keep public catalog discovery as the default; do not ask a general permission
  question about it. If the repository contains private or tenant-specific data,
  identify the actual conflict and ask which data belongs in the public catalog.
  Never expose private data or remove existing authentication to meet the default.
- Ask about desired behavior when source cannot establish it. Do not ask the
  developer questions that inspecting their repository can answer.
- Implement ODP only. Represent existing AEP and payment behavior accurately.
  Adding AEP, MPP, or x402 belongs to a separate integration.
- Do not install dependencies, edit application code, create commits, deploy,
  submit a listing, or execute a payment during the assessment.
- Once a plan is approved, work on one coherent task at a time. A reply of
  `go` authorizes the next stated step, not every subsequent step.
- End each stage with its outcome and a precise continuation such as:
  "Next step: type `go` to begin the repository assessment."
  When a decision is needed, request that decision instead of treating `go`
  as an answer to an unresolved choice.

## Keep one durable plan from the start

Once the repository is confirmed, load the
[integration queue template](https://www.offeringprotocol.org/integration-queue-template.md)
and create or reconcile `ODP-INTEGRATION-PLAN.md` there. Announce that it
holds interview answers, findings, decisions, and the eventual execution plan.
Do not wait until implementation planning or ask a separate checkpoint question.

During assessment, write only this planning file and, in coordinated mode, the
coordination plan. Application code and configuration remain unchanged. If the
template cannot be read or the file cannot be saved, report that limitation.
Preserve existing notes and unfinished work. Never store secrets or personal data.

Track the stage as Interview, Assessment, Plan awaiting approval, Implementation,
or Verification. Keep stage separate from whether work is blocked or waiting.
Before every response returning control to the developer, save confirmed answers,
source-backed findings, selected and excluded capabilities, unanswered questions,
the current stage, and the precise next action. Mark proposed choices pending,
not approved. This includes questions and suggestions to switch workflows.

Before suggesting another integration, record the reason, destination, and what
to reassess on return. Save before the suggestion: the developer may immediately
leave the session. Early planning does not authorize application changes.

On return, read the plan and verify current repository state. Reconcile new
capabilities and user changes rather than replaying stale tasks. If the plan is
missing, reassess and recreate it without assuming prior answers or completion.

## Sources

Use the [ODP documentation](https://www.offeringprotocol.org/documentation/) to
explain concepts and the [ODP specification](https://www.offeringprotocol.org/draft/)
to establish protocol requirements. Record the draft revision used in the plan.

Select one SDK based on the application's language and framework:

| Language             | Repository                                      |
| -------------------- | ----------------------------------------------- |
| Go                   | https://github.com/offering-protocol/odp-go     |
| Java                 | https://github.com/offering-protocol/odp-java   |
| Node.js / TypeScript | https://github.com/offering-protocol/odp-node   |
| Python               | https://github.com/offering-protocol/odp-python |
| Rust                 | https://github.com/offering-protocol/odp-rust   |

Read the selected SDK's documentation, public APIs, and relevant service examples.
Verify the installed or proposed package version; do not copy an API from a
different version or browse all five SDKs indiscriminately. If no SDK fits,
explain the gap and ask about the approach before planning implementation.

The specification governs protocol behavior. SDK source establishes the APIs
available in the selected version. Application source establishes current
behavior. Developer decisions establish target scope. Report conflicts among
these sources rather than silently weakening requirements or rewriting the
application to match an example.

## 1. Welcome

Begin with a short introduction:

> Welcome to the ODP integration process. ODP helps agents discover your service,
> understand its Offerings, and find the Actions they can take. We will confirm
> your goals, examine your application, agree on an integration plan, and
> implement it in reviewable steps. Existing authentication and payment behavior
> will be preserved.

Explain that this process supports both first-time integration and improvements
to an existing integration. Tell the developer that assessment comes before code
changes. Pause and invite them to begin the interview.

## 2. Confirm the target and goals

Ask the following questions in small groups, skipping answers already provided:

1. Which repository and application should receive ODP? Confirm the target when
   several applications or services share a repository.
2. Which SDK should we use: Go, Java, Node.js, Python, or Rust? Offer to recommend
   one after inspecting the application if the developer is unsure.
3. What does the service offer, and what should an agent be able to discover
   and do? Ask for one or two real examples.
4. Which service pattern fits: digital services or goods, physical goods,
   a marketplace, or another pattern?
5. Is this a first integration or an update? If updating, what outcome should
   change? An old plan is useful but is not required.
6. Which integration level is the intended starting point?
7. Are AEP or MPP/x402 integrations planned but not implemented? Existing support
   will be verified during assessment.

Explain patterns using concrete distinctions. A marketplace presents Offerings
from multiple sellers under the marketplace's brand. An aggregator exposing
each wrapped service on a dedicated origin can describe each origin as its own
ODP Service. Do not force an aggregator into a marketplace design.

Present these integration levels as planning choices, not protocol versions or
formal conformance tiers:

| Level       | Intended result                                                                                                                                                                                                               |
| ----------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Minimal     | A conformant Service Document and the required list/get Offering operations, backed by real application data. Include the fields and behavior required for the selected catalog.                                              |
| Recommended | Minimal plus useful descriptive details, images, pricing and available Actions; add search and Collections where they help callers find the Offerings.                                                                        |
| Complete    | All discovery features relevant to this application, potentially including richer search and filtering, Attribute Schemas, localization, and additional catalog relationships. Explain which features apply and which do not. |

Every level must satisfy the applicable protocol requirements. Complete does not
mean implementing every optional feature. Minimal does not mean a placeholder
catalog, and no level guarantees directory acceptance or search ranking.

Summarize the answers and identify what the repository assessment must establish.
Pause before scanning.

## 3. Inspect the current repository

Announce what you are inspecting. Keep application inspection read-only and bounded to the
confirmed application while updating the planning file. Do not print secrets or personal data.

Read the repository instructions and examine:

- Language, framework, routing, dependency versions, and startup configuration.
- Existing ODP documents, handlers, SDK usage, and any previous integration plan.
- Catalog data and how identifiers, descriptions, images, prices, variants, and
  availability are represented.
- Existing operations that an Offering's Action could refer to, their inputs,
  authentication, payment requirements, and responses.
- AEP discovery and request handling, if present.
- MPP/x402 middleware, endpoint configuration, supported options, and actual
  request handling, if present.
- Public origins, path prefixes, proxy configuration, and deployment constraints.
- Existing tests, validation, build commands, and uncommitted changes.

An installed package is not evidence of working protocol support. Trace how it
is configured and reached by requests. Separate verified source behavior from
runtime behavior that has not been exercised.

For an existing ODP integration, check the current code even if a plan marks it
complete. Preserve useful code and identify the difference between the current
implementation and the requested level. Do not regenerate the integration from
scratch just because its earlier plan is missing.

### Start from what the application already offers

Think from the application's existing capabilities toward ODP, not from an SDK
example toward a new application. Find what people can browse or buy in the
browser and what software can request through its REST API. Trace those
experiences to the underlying records, business logic, and request handlers.

Look for browser catalogs, product and pricing pages, and API capabilities such
as search, extraction, report generation, booking, or downloads. An application
may have either source or both. Before asking the developer to design Offerings,
propose concrete mappings using actual repository findings:

> I found a browser catalog with 40 products and API endpoints for search and
> report generation. Do you want ODP to expose the products, the API services,
> or both?

Use those details only if verified. Present a short selection table:

| Capability found        | Source evidence            | Proposed ODP representation                                       | Developer selection |
| ----------------------- | -------------------------- | ----------------------------------------------------------------- | ------------------- |
| Browser product catalog | Records and rendering path | Products as Offerings; useful groupings as Collections            | Include or exclude  |
| Search API              | Route, inputs, and handler | Search capability as an Offering with an Action accepting a query | Include or exclude  |
| Report-generation API   | Route, inputs, and handler | Report capability as an Offering with a generation Action         | Include or exclude  |

These rows illustrate the format, not required features. Replace them with actual
findings and explain the value of each mapping. Exclude unrelated administrative
endpoints, internal helpers, and sensitive operations unless the developer
identifies a specific authorized integration need.

An endpoint is not automatically an Offering. Model the useful product or
capability the caller discovers, then connect its available operations through
Actions. Multiple endpoints may support one Offering. A request parameter such
as a search phrase does not become a separate Offering.

Reuse application data and behavior instead of scraping the application's own
HTML or maintaining a second catalog. If a browser operation lacks a suitable
callable handler, explain any application API work needed and obtain approval
before including it. Do not advertise an Action whose target does not exist.

Follow this order: discover capabilities, propose mappings, obtain the developer's
selection, then resolve the detailed ODP design. Record excluded capabilities
as well as selected ones so a later run can revisit the decision.

Present a concise assessment with source locations:

| Area           | What exists                    | ODP implications                      | Open question              |
| -------------- | ------------------------------ | ------------------------------------- | -------------------------- |
| Catalog        | Actual source and structure    | Proposed Offerings and Collections    | Only unresolved choices    |
| Actions        | Actual endpoints and inputs    | How agents discover available actions | Missing mappings           |
| Authentication | Verified implementation        | Correct ODP advertisement             | Existing conflicts         |
| Payments       | Verified protocols and options | Correct ODP advertisement             | Planned versus implemented |
| Delivery       | Routes and deployment setup    | Discovery and catalog URLs            | Unresolved hosting choices |

Explain findings before asking the next set of questions. Pause for the developer
to review the assessment.

## 4. Resolve application-specific choices

Confirm the developer's selection from the assessment's candidate capabilities.
Reuse any selection already provided rather than asking again. Then resolve
only unanswered design questions for the selected capabilities:

- Which existing records become Offerings, and which identifiers are stable?
- Which choices identify different Offerings, and which are request parameters
  such as a search phrase, quantity, or selectable option?
- Would Collections help organize this catalog, or would they add no value?
- Which existing endpoints should be discoverable through Actions?
- How should search, pagination, filtering, and sorting use existing data access?
- Which metadata is public, localized, or specific to an authenticated caller?
- Which origin and endpoint base will be used in development and deployment?

Recommend a mapping with concrete examples from the application. Explain the
consequences without asking the developer to invent ODP terminology.

### AEP and payments remain separate

If AEP exists, model its relationship to ODP and the actual authentication
requirements. If MPP/x402 endpoints exist, model the Offerings, Actions, payment
protocols, options, and authentication requirements associated with them.
Protocol advertisement does not assert that every endpoint supports that protocol.

Advertise only options the service accepts under that payment protocol.
Do not populate the full ODP enum or the full list supported by an installed SDK.

When a related integration is absent, omit its advertisement. If the developer
plans to add it, offer two concrete choices:

> Continue ODP using the capabilities implemented today, or pause and complete
> the separate integration before returning here.

Link to the appropriate guide:

- [AEP integration](https://www.aep.foundation/integration.md)
- [InFlow Payments integration](https://app.inflowpay.ai/integration.md)

Read the linked guide before handing the developer to it. If it is empty or
unavailable, state that clearly; do not invent instructions or silently perform
the other integration inside this workflow.

Existing authentication is not automatically AEP. An ODP operation advertised
with optional or required authentication requires enrollment advertisement under
the current draft. If the application cannot satisfy that requirement, explain
the conflict and pause for a decision; do not remove protection or falsely
advertise AEP.

After a separate integration is completed, reassess the current repository.
Do not rely on the state recorded before the pause.

Summarize the final scope in concrete features and exclusions. Obtain agreement
before expanding the planning file into executable implementation tasks.

## 5. Complete the executable plan

Expand the existing `ODP-INTEGRATION-PLAN.md` using the confirmed interview and
assessment results. Preserve their evidence and decisions. Set the stage to
Plan awaiting approval; early notes are not an approved implementation plan.

Include:

- Confirmed application, SDK version, specification revision, and selected scope.
- Source-backed current state, unresolved questions, and approved decisions.
- Exact mappings for discovery, catalog operations, and existing Action targets.
- Selected and excluded browser/API capabilities, their data sources and handlers,
  and explicitly approved application API work needed to expose them.
- Actual AEP/payment support and intentionally omitted capabilities.
- Ordered implementation tasks with outputs, dependencies, and verification.
- Relevant failure cases, compatibility concerns, and deployment constraints.
- Affected existing browser and API flows and how to verify they remain intact.
- Separate tasks for local verification, deployment verification, and directory
  submission when those activities are approved.

Plan the required `list-offerings` and `get-offering` operations and verify
their paths and response shapes against the selected specification and SDK.
Advertise optional operations only when implemented. Follow the application's
existing architecture rather than copying an example's storage model.

Present the plan path, proposed changes, checks, and first task. Ask for approval.
Creating the plan does not authorize implementation.

## 6. Implement one task at a time

Execute the next approved task using the plan's review and verification process.
Check applicable requirements before coding, review each subsystem independently,
and trace the completed behavior through the actual application.

Use existing data sources and endpoint behavior. Avoid adding a second catalog,
authentication system, payment implementation, or storage layer merely to make
an SDK example fit.

After each task:

- Update the plan with the result and evidence.
- Explain what changed and which requirements were verified.
- Report the actual checks run, including failures and checks not run.
- Record discoveries, unresolved decisions, and deferred work.
- State the next task and pause for `go`.

If a discovery changes the approved design, ask before proceeding. Do not bury
the decision in code, tests, or an expanded task list.

## Exit criteria to generate in the plan

End the generated plan with two separate, cumulative acceptance groups:

1. **Project acceptance:** derive the project's prescribed unit tests, integration
   tests, coverage thresholds, static analysis, regression checks, and other
   agreed quality gates from its source and instructions. These remain required.
2. **InFlow acceptance:** verify the integration against a running system using
   InFlow CLI and the role-specific checks below. These do not replace project
   tests or justify lowering their thresholds.

For every criterion, record the exact command or procedure, environment, target,
prerequisites, expected result, evidence, and state. Verify CLI syntax and options
against its installed version before generating runnable commands. Command names
below are examples, not complete invocations. Never save secrets in command logs.

Generate `inflow odp inspect` and applicable catalog commands against the running
Service, including listing Offerings and retrieving a real Offering. Check the
advertised Actions and the selected optional capabilities. When AEP or payments
are part of the approved combined integration, include an authorized end-to-end
check using their child plans against the same Service; never pay simply to test
discovery.

Include Directory validation and publication as explicit exit criteria. Confirm
the intended directory and origin, obtain permission to submit, and record the
submission result separately from a confirmed listing. If publication is blocked
by admission rules, deployment, or approval, keep that criterion pending and
report the required next action. Do not silently expand protocol scope to satisfy
an admission rule.

Distinguish implementation complete, local verification, deployed verification,
and external publication. Obtain explicit authorization for enrollment, credential
changes, payments, and publication. Pending approval or unavailable infrastructure
is not a passing criterion. A developer-approved deferral remains visible in the
handoff rather than being reported as end-to-end success.

## 7. Verify and hand off

Verify affected existing flows identified in the plan, not only the new protocol
behavior. Examples include browser login and checkout, catalog navigation, and
existing API credentials, permissions, and tenant restrictions. Select relevant
flows and use existing tests or controlled test environments. This does not
authorize real purchases or a new application-wide test framework. Report
affected flows that could not be verified.

Run the prescribed repository checks and relevant integration checks against the
implemented application. Validate the Service Document and the advertised catalog
operations using the selected SDK and specification. Check actual URL resolution,
response shapes, identifiers, pagination, and advertised authentication behavior
where applicable. A test that mocks the uncertain behavior is not proof of it.

Verify that Offerings and Actions describe the application accurately. Confirm
that absent protocols are omitted and advertised payment options match the
configured service. Do not execute a paid or otherwise destructive Action merely
to test discovery.

Review the final diff for unrelated edits, generated drift, security problems,
and differences between the tested tree and the delivered tree.

Report separately:

- Implemented and locally verified.
- Awaiting deployment.
- Verified on the deployed origin.
- Submitted to a directory, if explicitly authorized.
- Outstanding failures, limitations, or developer decisions.

A conformant ODP implementation does not automatically satisfy a directory's
separate admission rules. Deployment and directory submission require explicit
authorization. Do not mark them complete because local tests passed.

Finish with the plan path, files changed, exact verification outcomes, and the
single next action for the developer.

## Run this guide again

A developer can return after adding AEP, payments, more Offerings, or a larger
application. Repeat the interview and current-state assessment; use previous
answers as context, not immutable requirements.

For example, a Minimal integration may already expose three Offerings. A later
run can discover newly implemented AEP and MPP endpoints and plan a Complete
integration that advertises them and adds the applicable discovery features.
Keep working parts, verify them again, and plan only the approved changes.