# Validation record

## Automated tests

The latest local validation completed successfully:

- LWC Jest: 1 suite, 6 tests passed.
- Apex: `AccountRelationshipControllerTest`, 6 tests passed.

The Apex suite covers direct-relationship DTOs and counts, bounded account lookup, invalid input, progressive expansion, and a restricted-user `WITH USER_MODE` error path. The Jest suite covers empty state transformations, search and direct-object filtering, expanded secondary-node visibility, counts, connected-node focus, labels, and tooltips.

## Lightning Experience validation

A clearly labelled synthetic Account dataset was used solely in a non-production Developer Edition org. The initial graph showed 10 direct nodes. Explicit Account expansion added four secondary nodes: one child Account, one Task, one Event, and one Asset. Selection, contextual details, filtering, and native record navigation were verified. No customer records, credentials, org identifiers, usernames, or screenshots are included in this repository.

## Dependency audit

The development dependency chain has three low-severity `npm audit` findings in the Jest/LWC compiler chain: `@salesforce/sfdx-lwc-jest` → `@lwc/compiler` → `@babel/core` (GHSA-4x5r-pxfx-6jf8). Production dependencies report zero findings. The available remediation requires a breaking major upgrade of `@salesforce/sfdx-lwc-jest`; it was not applied automatically.
