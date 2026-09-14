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
