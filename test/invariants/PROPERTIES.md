# Safer Safe Invariant tests

/!\ As of writing, Forge Foundry does not use corpus and coverage guided fuzzing
by default - use the nightly version (1.3.0) if desired: `foundryup --install nightly` /!\

## Scope

- `SafeEntrypoint`
- `SafeEntrypointFactory`
- `SimpleActions`
- `SimpleTransfers`
- `CappedTokenTransfers` and hub
- `AllowanceClaimor`

## Invariants

The core of the security relying on the Safe contract, these tests are privileging non-revertion/system "frozen" state.

### Cap & Accounting Invariants

| Invariant | Description |
|-----------|-------------|
| `invariant_capNeverExceeded` | Cap limits are never exceeded in any hub (accounting for epoch boundaries) |

### Ghost State Invariants

| Invariant | Description |
|-----------|-------------|
| `invariant_sanity_ghostStateConsistency` | Every hash in ghost state has a corresponding non-zero action builder address |

### Approval & Timing Invariants

| Invariant | Description |
|-----------|-------------|
| `invariant_queuedTransactionsHaveValidApprovals` | Queued transactions only exist for approved action builders/hubs with valid approvals. Pre-approved transactions must have approval either directly or through parent hub |
| `invariant_approvalExpiriesAreValid` | Approval expiries never exceed MAX_APPROVAL_DURATION from the current timestamp |
| `invariant_transactionTimingIsCorrect` | Transaction timing is always correct: expiresAt > executableAt, and executableAt >= queuedAt |
| `invariant_preApprovedTransactionsUsedShortDelay` | Pre-approved transactions use SHORT_TX_EXECUTION_DELAY at queue time (not LONG_TX_EXECUTION_DELAY) |

### Queue Consistency Invariants

| Invariant | Description |
|-----------|-------------|
| `invariant_queueHasNoDuplicates` | Queue has no duplicate action builder addresses |
| `invariant_allQueuedBuildersHaveNonZeroExpiry` | All queued action builders have non-zero expiry timestamp |
| `invariant_queueMappingConsistency` | Queue array and transactionsInfo mapping are always in sync: builders in queue have non-zero expiry, and builders with non-zero expiry are in queue |

## Setup

The different action hub targets are all a single mock contract, `ActionTarget`, which is used to test the correct interaction with any arbitrary external contract (by setting flags which are then asserted in the invariants).

Each action builders and hubs are in a dedicated handler, handling both queueing and execution. This should allow enough flexibility to add new action builders in the future.

## Delays assumptions

~~Some assumptions are introduced as extra-constraints to the reconfiguration of the entrypoint:~~

~~- `SHORT_TX_EXECUTION_DELAY` must be less than `LONG_TX_EXECUTION_DELAY`~~
~~- `LONG_TX_EXECUTION_DELAY` must be more than `SHORT_TX_EXECUTION_DELAY`~~
~~- `TX_EXPIRY_DELAY` must be less than 10 years.~~
~~These constraints prevent overflows in `_queueTransaction` (as described in the internal review findings).~~

update: this has now been fixed
