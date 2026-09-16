---
title: Alpenglow
description:
  "Learn about Alpenglow and its impact on Solana validators, Geyser plugins,
  and on-chain programs."
---

Alpenglow is Solana's upcoming consensus protocol. It replaces Tower BFT's
voting and finality logic with Votor and is expected to activate as part of the
Agave v4.3 release cycle.

For the protocol design, see:

- The
  [Alpenglow white paper](https://drive.google.com/file/d/1RPJ9OyohFMuFfLmTB5ydPYlrKTIlUxq9/view)
  for the complete protocol design.
- [SIMD-0326: Alpenglow](https://github.com/solana-foundation/solana-improvement-documents/blob/main/proposals/0326-alpenglow.md)
  for the Votor consensus changes.

## Operator Changes

For details about changes introduced with Alpenglow, see:

- [Validator admission ticket](../operations/guides/vote-accounts.md#validator-admission-ticket)
  for expected charges, vote account funding requirements, and commission
  collector configuration.
- [Validator failover](../operations/guides/validator-failover.md#changes-for-alpenglow)
  for vote history file handling and failover steps.
- [Commitment status](./commitments.md#alpenglow) for how the Confirmed and
  Finalized commitment statuses change.

## Consensus Access for Unstaked Validators

By default, Votor consensus messages are exchanged only among validators in the
admitted set. The protocol selects this set each epoch and automatically deducts
the validator admission ticket (VAT) from their vote accounts. Nodes outside the
set can still obtain consensus information through the following tiers, with
different latency levels.

Alpenglow targets finality in roughly 150 ms under normal network conditions.
Depending on the tier, an unstaked node may learn of finalization later.

### Tier 3: Receive Consensus Information Through Blocks

Each leader includes its latest known finalization certificate in the footer of
the block it produces.

No additional configuration is required: Agave automatically processes these
certificates and updates local commitment status, even on nodes outside the
admitted set.

Nodes using this path learn of finalization when they receive a later block that
carries the certificate. Compared with direct Votor delivery, this typically
adds up to one produced-block interval and can take longer when blocks are
skipped or delayed.

### Tier 2: Partner with an Admitted Validator

For lower latency, an unstaked node can receive Votor consensus messages from an
admitted validator. The admitted validator must pass the unstaked node's
gossip identity to the following `agave-validator` CLI option:

```bash
--votor-peer-overrides <UNSTAKED_PARTNER_IDENTITY>...
```

The admitted validator then sends Votor messages directly to each configured identity.
The additional delay is primarily the network latency between the partner nodes.

:::caution

If none of an unstaked node's configured partners are reachable, the node stops
receiving Votor messages directly but still learns finality from later block
footers through Tier 3. Consider partnering with multiple admitted validators
for extra resilience.

:::

### Tier 1: Become an Admitted Validator

For the lowest latency, operators can register a valid vote account with BLS pubkey,
delegate stake to the validator and keep enough SOL in its vote account to cover the VAT.
At most 2,000 eligible validators are admitted, with priority given to higher stake, so
delegate the minimum required to acquire a seat (e.g. 1 SOL).

With such little SOL delegated, an admitted validator is extremely unlikely
to be selected for block production. It also earns negligible inflation rewards
making this an unprofitable setup.

However this option may still be suitable for RPC operators that need to serve the
freshest possible data but cannot geo-locate with a partner validator that is admitted.

## Block Footers and Geyser Plugins

Alpenglow blocks end with a versioned footer containing various metadata.

For the block footer design, see:

- [SIMD-0307: Add Block Footer](https://github.com/solana-foundation/solana-improvement-documents/blob/main/proposals/0307-add-block-footer.md)

For ease of parsing [Agave v4.3 adds an opt-in Geyser notification](https://github.com/anza-xyz/agave/blob/master/CHANGELOG.md#changes-5)
for Alpenglow block footers. Plugins that need footer data should return `true`
from `block_footer_notifications_enabled()` and implement
`notify_block_footer()`. Footer callbacks preserve their ordering relative to entry
notifications, but plugins do not need to enable entry notifications to receive
them.

## Clock Sysvar

:::note

After Alpenglow activates, the Clock sysvar retains its existing layout and
whole-second resolution, but the `unix_timestamp` field has slightly different
semantics for on-chain programs. During transaction execution, it estimates when
the parent block ended rather than when the current block began.
The `slot` field still identifies the current slot. Continue treating
the timestamp as approximate and avoid relying on it for high precision.

:::
