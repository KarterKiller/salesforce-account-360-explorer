# Salesforce Account 360 Relationship Explorer

A portfolio-ready Salesforce Lightning application that makes an Account's CRM network explorable as an interactive, force-directed SVG graph. It turns scattered customer, pipeline, and service information into a focused relationship map for account teams.

## Business use case

Account teams often need to understand the people, commercial activity, service history, and operational context around an Account without opening multiple related lists. This application provides an Account 360 exploration surface for sales and service users while preserving Salesforce sharing and field-level access.

## Architecture

The application combines a Lightning Web Component, Apex DTOs, Salesforce standard objects, and a local D3.js 7.9.0 static resource. See [the architecture diagram](docs/architecture.md).

```text
LWC + SLDS + SVG  ->  Apex controller  ->  Salesforce CRM records
       |                    |
       +-- local D3 7.9.0 --+-- inherited sharing + WITH USER_MODE
```

### Components

- `accountRelationshipExplorer` — responsive dashboard, graph lifecycle, filters, selection, and `NavigationMixin` record navigation.
- `relationshipGraphUtils` — testable graph transformations, connected-node focus logic, labels, and tooltips.
- `AccountRelationshipController` — bounded, security-enforced direct and progressive relationship queries.
- `d3.resource` — pinned, local D3.js 7.9.0; it is loaded through `lightning/platformResourceLoader`, never from a CDN.

## Supported CRM relationships

The initial graph is deliberately bounded to the selected Account and its direct Contacts, Opportunities, and Cases.

Progressive exploration is opt-in:

- Account branch: parent/child Accounts, Assets, Tasks, Events, Contracts, and Orders.
- Opportunity branch: Tasks and Events.

Only accessible records are returned. Every secondary query is independently capped at 25 records; direct relationship queries are capped at 75 records per object. Quotes are not included because they are not available in the demonstration org.

## Experience

- Force-directed D3 layout with collision handling and grouped placement.
- Zoom, pan, drag, automatic fit, reset, and reduced-motion-aware transitions.
- Search, direct-object filters, contextual details, accessible selection, and native Salesforce record navigation.
- Progressive branch expansion with client-side ID deduplication.
- Smooth links, hover tooltips, and selected-path emphasis with unrelated nodes dimmed.
- Gradient SVG node faces, soft halos, shadows, object icons, refined label containers, and a subtle graph texture.
- Clear empty state when no accessible direct relationships exist.

## Security

`AccountRelationshipController` is declared `inherited sharing`. Its SOQL uses `WITH USER_MODE`, queries are bounded, and it returns purpose-built DTOs instead of raw sObjects. This enforces record sharing, CRUD, and field-level security for the running user. Authorization failures return a generalized message rather than exposing inaccessible record or field details.

Assign the included **Account 360 Explorer** permission set to users who need access to the Apex class. Object and field access remain governed by your least-privilege Salesforce configuration.

## Deploy

Prerequisites: Salesforce CLI, an authenticated non-production org, and Node.js compatible with the installed Jest tooling.

```powershell
npm install
npm run test:unit
sf project deploy start --target-org YOUR_ORG_ALIAS --source-dir force-app
sf apex run test --target-org YOUR_ORG_ALIAS --tests AccountRelationshipControllerTest --result-format human
```

After deployment, assign the `Account_360_Explorer` permission set and add the supplied **Account 360 Explorer** navigation item/App Page to a Lightning app. The component includes its own Account selector, so it can be used without record-page context.

## Validation

Latest project validation:

- Apex: 6/6 tests passed, including progressive expansion and restricted-access behavior.
- LWC Jest: 6/6 tests passed.
- Lightning Experience: validated with a clearly labelled synthetic dataset; initial view contained only direct relationships, then showed four additional Account-branch records after explicit expansion.

See [validation notes](docs/validation.md) for the exact non-sensitive validation scope.

## Limitations

- Branches support one-way progressive expansion; branch collapse/removal is not yet implemented. The graph's **Expand** control changes canvas size only.
- Supported relationships are intentionally scoped to avoid excessive SOQL and visual overload.
- Node positions are simulation-driven and can vary slightly between renders.
- The sample dataset is synthetic and is not included in this repository.

## Third-party notices

D3.js 7.9.0 is included as a Salesforce static resource under the ISC License. Its source, integrity values, and license notice are documented in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

## Screenshots

No sanitized local dashboard screenshots were available at publication-preparation time. See [the screenshot placeholder](docs/screenshots/README.md); do not add real customer data to screenshots.
