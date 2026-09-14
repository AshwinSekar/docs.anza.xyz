---
title: "Validator Guide: Vote Account Management"
sidebar_position: 5
sidebar_label: Vote Account Management
pagination_label: "Validator Guides: Vote Account Management"
---

This page describes how to set up an on-chain _vote account_. Creating a vote
account is needed if you plan to run a validator node on Solana.

## Create a Vote Account

A vote account can be created with the
`create-vote-account` command. The
vote account can be configured when first created or after the validator is
running. All aspects of the vote account can be changed except for the
[vote account address](#vote-account-address), which is fixed for the lifetime
of the account.

### Configure an Existing Vote Account

- To change the [validator identity](#validator-identity), use
  `vote-update-validator`.
- To change the [vote authority](#vote-authority), use
  `vote-authorize-voter-checked`.
- To set the BLS public key associated with the
  [vote authority](#vote-authority), use
  `vote-authorize-voter-checked`
  after SIMD-0387 is active on the cluster.
- To change the [authorized withdrawer](#authorized-withdrawer), use
  `vote-authorize-withdrawer-checked`.
- To change the [commission](#commission), use
  `vote-update-commission`.
- To change a [commission collector](#fund-the-vat-with-commission-revenue), use
  `vote-update-commission-collector`.

### Set the BLS Public Key

Voting validators must set the BLS public key associated with their authorized voter.

You must use `solana` version 4.1.0 or higher.

For almost all validators, the authorized voter is the validator identity. If
you are unsure which keypair is the current authorized voter, run:

```bash
solana vote-account <VOTE_ACCOUNT> | grep "Vote Authority"
```

Then set the BLS public key by running the following command.

```bash
solana vote-authorize-voter-checked <VOTE_ACCOUNT> <AUTHORIZED_VOTER_KEYPAIR> <AUTHORIZED_VOTER_KEYPAIR>
```

This does not change the authorized voter. It fills in the BLS public key
associated with the authorized voter.

For a new vote account, follow the normal
[create vote account](#create-a-vote-account) instructions first, then run the
same `vote-authorize-voter-checked` command above to set the BLS public key.

To check whether the BLS public key is set on chain, run:

```bash
solana vote-account <VOTE_ACCOUNT> | grep "BLS Public Key"
```

If the command does not print a `BLS Public Key` line, the vote account does not
have a BLS public key set.

To view the BLS public key derived from the authorized voter keypair locally,
run:

```bash
solana-keygen bls_pubkey <AUTHORIZED_VOTER_KEYPAIR>
```

## Vote Account Structure

### Vote Account Address

A vote account is created at an address that is either the public key of a
keypair file, or at a derived address based on a keypair file's public key and a
seed string.

The address of a vote account is never needed to sign any transactions, but is
just used to look up the account information.

When someone wants to
[delegate tokens in a stake account](https://solana.com/staking),
the delegation command is pointed at the vote account address of the validator
to whom the token-holder wants to delegate.

### Validator Admission Ticket

Under Alpenglow, the
[validator admission ticket (VAT)](https://github.com/solana-foundation/solana-improvement-documents/blob/main/proposals/0357-alpenglow_validator_admission_ticket.md)
is burned from each admitted validator's vote account once per epoch. The vote
account must hold the ticket amount in addition to its rent-exempt minimum. If
its balance is too low, the validator is not admitted to vote or produce blocks
in the following epoch.

For example, a ticket deducted at the start of epoch 100 pays for admission in
epoch 101.

#### Expected Charge

[SIMD-0525](https://github.com/solana-foundation/solana-improvement-documents/blob/main/proposals/0525-reduce-slot-times.md#validator-admission-ticket-scaling)
scales the VAT with the effective target slot time, keeping its final cost at
approximately 0.8 SOL per day. With
[Mainnet Beta currently targeting 300 ms](https://github.com/anza-xyz/agave/wiki/Feature-Gate-Tracker-Schedule),
the expected VAT after Alpenglow activates is 1.2 SOL per roughly 36-hour epoch.
The full rollout schedule is:

| Target slot time  | Approximate epoch duration | VAT per epoch |
| ----------------- | -------------------------- | ------------- |
| 400 ms (baseline) | 48 hours                   | 1.6 SOL       |
| 350 ms (previous) | 42 hours                   | 1.4 SOL       |
| 300 ms (current)  | 36 hours                   | 1.2 SOL       |
| 250 ms (planned)  | 30 hours                   | 1.0 SOL       |
| 200 ms (planned)  | 24 hours                   | 0.8 SOL       |

These are fixed per-epoch charges for each slot-time stage. The charge uses the
stage for the epoch being admitted, and actual epoch wall time can vary.

Note: that slot time feature activations are delayed by 1 epoch.
For transition epochs consult this table, imagining that the 250ms feature flag
activates at the start of epoch E + 1:

| Epoch Transition | Feature Activation   | Slot Time in new epoch | VAT Amount | Admission for Epoch |
| ---------------- | -------------------- | ---------------------- | ---------- | ------------------- |
| E - 1 -> E       | None                 | 300 ms                 | 1.2 SOL    | E + 1               |
| E -> E + 1       | 250ms flag activates | 300 ms                 | 1.2 SOL    | E + 2               |
| E + 1 -> E + 2   | 250ms effective      | 250 ms                 | 1.0 SOL    | E + 3               |
| E + 2 -> E + 3   | None                 | 250 ms                 | 1.0 SOL    | E + 4               |

Here the 250ms feature flag activated at the start of E + 1, but the admission
ticket charges at the start of E + 1 was still 1.2 SOL for admission in E + 2.
E + 2 was the first epoch with 250ms slot times, and the admission ticket charged
at the beginning of E + 2 was decreased to 1.0 SOL.

#### Fund the VAT with Commission Revenue

[SIMD-0232](https://github.com/solana-foundation/solana-improvement-documents/blob/main/proposals/0232-custom-commission-collector.md)
lets validators choose separate collector accounts for inflation rewards and
block revenue. The inflation rewards collector defaults to the vote account,
while the block revenue collector defaults to the validator identity. Directing
both commission streams to the vote account can replenish its VAT balance and
reduce the need for manual top-ups.

To direct block revenue commission to the vote account, run:

```bash
solana vote-update-commission-collector \
  <VOTE_ACCOUNT_ADDRESS> \
  block-revenue \
  <VOTE_ACCOUNT_ADDRESS> \
  <AUTHORIZED_WITHDRAWER_KEYPAIR>
```

A change to the block revenue commission made during Epoch E
takes effect in E + 2.

The inflation rewards collector already defaults to the vote account. To set it
explicitly, run:

```bash
solana vote-update-commission-collector \
  <VOTE_ACCOUNT_ADDRESS> \
  inflation-rewards \
  <VOTE_ACCOUNT_ADDRESS> \
  <AUTHORIZED_WITHDRAWER_KEYPAIR>
```

A change to the inflation rewards commission made during Epoch E
takes effect in E + 1.

The authorized withdrawer must sign these transactions.
Verify both collectors afterward with:

```bash
solana vote-account <VOTE_ACCOUNT_ADDRESS>
```

:::caution

Commission income is not guaranteed to cover the VAT, and rewards arriving at an
epoch boundary cannot rescue an account that is already underfunded when
admission is evaluated. Pre-fund the first ticket, then monitor the vote account
and maintain at least its rent-exempt minimum plus the next VAT charge, with an
additional buffer.

:::

### Validator Identity

The _validator identity_ is a system account that is used to pay for all the
vote transaction fees submitted to the vote account. Because the validator is
expected to vote on most valid blocks it receives, the validator identity
account is frequently (potentially multiple times per second) signing
transactions and paying fees. For this reason the validator identity keypair
must be stored as a "hot wallet" in a keypair file on the same system the
validator process is running.

Because a hot wallet is generally less secure than an offline or "cold" wallet,
the validator operator may choose to store only enough SOL on the identity
account to cover voting fees for a limited amount of time, such as a few weeks
or months. The validator identity account could be periodically topped off from
a more secure wallet.

This practice can reduce the risk of loss of funds if the validator node's disk
or file system becomes compromised or corrupted.

The validator identity is required to be provided when a vote account is
created. The validator identity can also be changed after an account is created
by using the
`vote-update-validator` command.

### Vote Authority

The _vote authority_ keypair is used to sign each vote transaction the validator
node wants to submit to the cluster. This doesn't necessarily have to be unique
from the validator identity, as you will see later in this document. Because the
vote authority, like the validator identity, is signing transactions frequently,
this also must be a hot keypair on the same file system as the validator
process.

The vote authority can be set to the same address as the validator identity. If
the validator identity is also the vote authority, only one signature per vote
transaction is needed in order to both sign the vote and pay the transaction
fee. Because transaction fees on Solana are assessed per-signature, having one
signer instead of two will result in half the transaction fee paid compared to
setting the vote authority and validator identity to two different accounts.

The vote authority can be set when the vote account is created. If it is not
provided, the default behavior is to assign it the same as the validator
identity. The vote authority can be changed later with the
`vote-authorize-voter-checked`
command.

The vote authority can be changed at most once per epoch. If the authority is
changed with
`vote-authorize-voter-checked`,
this will not take effect until the beginning of the next epoch. To support a
smooth transition of the vote signing, `agave-validator` allows the
`--authorized-voter` argument to be specified multiple times. This allows the
validator process to keep voting successfully when the network reaches an epoch
boundary at which the validator's vote authority account changes.

### Authorized Withdrawer

The _authorized withdrawer_ keypair is used to withdraw funds from a vote
account using the
`withdraw-from-vote-account`
command. Any network rewards a validator earns are deposited into the vote
account and are only retrievable by signing with the authorized withdrawer
keypair.

The authorized withdrawer is also required to sign any transaction to change a
vote account's [commission](#commission), and to change the validator identity
on a vote account.

Because theft of an authorized withdrawer keypair can give complete control over
the operation of a validator to an attacker, it is advised to keep the withdraw
authority keypair in an offline/cold wallet in a secure location. The withdraw
authority keypair is not needed during operation of a validator and should not
stored on the validator itself.

The authorized withdrawer must be set when the vote account is created. It must
not be set to a keypair that is the same as either the validator identity
keypair or the vote authority keypair.

The authorized withdrawer can be changed later with the
`vote-authorize-withdrawer-checked`
command.

### Commission

_Commission_ is the percent of network rewards earned by a validator that are
deposited into the validator's vote account. The remainder of the rewards are
distributed to all of the stake accounts delegated to that vote account,
proportional to the active stake weight of each stake account.

For example, if a vote account has a commission of 10%, for all rewards earned
by that validator in a given epoch, 10% of these rewards will be deposited into
the vote account in the first block of the following epoch. The remaining 90%
will be deposited into delegated stake accounts as immediately active stake.

A validator may choose to set a low commission to try to attract more stake
delegations as a lower commission results in a larger percentage of rewards
passed along to the delegator. As there are costs associated with setting up and
operating a validator node, a validator would ideally set a high enough
commission to at least cover their expenses.

Commission can be set upon vote account creation with the `--commission` option.
If it is not provided, it will default to 100%, which will result in all rewards
deposited in the vote account, and none passed on to any delegated stake
accounts.

Commission can also be changed later with the
`vote-update-commission` command.

When setting the commission, only integer values in the set [0-100] are
accepted. The integer represents the number of percentage points for the
commission, so creating an account with `--commission 10` will set a 10%
commission.

Note that validators can only update their commission during the first half of
any epoch. This prevents validators from stealing delegator rewards by setting a
low commission, increasing it right before the end of the epoch, and then
changing it back after reward distribution.

## Key Rotation

Rotating the vote account authority keys requires special handling when dealing
with a live validator.

Note that vote account key rotation has no effect on the stake accounts that
have been delegated to the vote account. For example it is possible to use key
rotation to transfer all authority of a vote account from one entity to another
without any impact to staking rewards.

### Vote Account Validator Identity

You will need access to the _authorized withdrawer_ keypair for the vote account
to change the validator identity. The following steps assume that
`~/authorized_withdrawer.json` is that keypair.

1. Create the new validator identity keypair,
   `solana-keygen new -o ~/new-validator-keypair.json`.
2. Ensure that the new identity account has been funded,
   `solana transfer ~/new-validator-keypair.json 500`.
3. Run
   `solana vote-update-validator ~/vote-account-keypair.json ~/new-validator-keypair.json ~/authorized_withdrawer.json`
   to modify the validator identity in your vote account
4. Restart your validator with the new identity keypair for the `--identity`
   argument

**Additional steps are required if your validator has stake.** The leader
schedule is computed two epochs in advance. Therefore if your old validator
identity was in the leader schedule, it will remain in the leader schedule for
up to two epochs after the validator identity change. If extra steps are not
taken your validator will produce no blocks until your new validator identity is
added to the leader schedule.

After your validator is restarted with the new identity keypair, per step 4,
start a second non-voting validator on a different machine with the old identity
keypair without providing the `--vote-account` argument, as well as with the
`--no-wait-for-vote-to-start-leader` argument.

This temporary validator should be run for two full epochs. During this time it
will:

- Produce blocks for the remaining slots that are assigned to your old validator
  identity
- Receive the transaction fees and rent rewards for your old validator identity

It is safe to stop this temporary validator when your old validator identity is
no longer listed in the `solana leader-schedule` output.

### Vote Account Authorized Voter

The _vote authority_ keypair may only be changed at epoch boundaries and
requires some additional arguments to `agave-validator` for a seamless
migration.

1. Run `solana epoch-info`. If there is not much time remaining time in the
   current epoch, consider waiting for the next epoch to allow your validator
   plenty of time to restart and catch up.
2. Create the new vote authority keypair,
   `solana-keygen new -o ~/new-vote-authority.json`.
3. Determine the current _vote authority_ keypair by running
   `solana vote-account ~/vote-account-keypair.json`. It may be validator's
   identity account (the default) or some other keypair. The following steps
   assume that `~/validator-keypair.json` is that keypair.
4. Run
   `solana vote-authorize-voter-checked ~/vote-account-keypair.json ~/validator-keypair.json ~/new-vote-authority.json`.
   The new vote authority is scheduled to become active starting at the next
   epoch.
5. `agave-validator` now needs to be restarted with the old and new vote
   authority keypairs, so that it can smoothly transition at the next epoch. Add
   the two arguments on restart:
   `--authorized-voter ~/validator-keypair.json --authorized-voter ~/new-vote-authority.json`
6. After the cluster reaches the next epoch, remove the
   `--authorized-voter ~/validator-keypair.json` argument and restart
   `agave-validator`, as the old vote authority keypair is no longer required.

### Vote Account Authorized Withdrawer

No special handling or timing considerations are required. Use the
`solana vote-authorize-withdrawer-checked` command as needed.

### Consider Durable Nonces for a Trustless Transfer of the Authorized Voter or Withdrawer

If the Authorized Voter or Withdrawer is to be transferred to another entity
then a two-stage signing process using a
[Durable Nonce](../../cli/examples/durable-nonce.md) is recommended.

1. Entity B creates a durable nonce using `solana create-nonce-account`
2. Entity B then runs a `solana vote-authorize-voter-checked` or
   `solana vote-authorize-withdrawer-checked` command, including:

- the `--sign-only` argument
- the `--nonce`, `--nonce-authority`, and `--blockhash` arguments to specify the
  nonce particulars
- the address of the Entity A's existing authority, and the keypair for Entity
  B's new authority

3. When the `solana vote-authorize-...-checked` command successfully executes,
   it will output transaction signatures that Entity B must share with Entity A
4. Entity A then runs a similar `solana vote-authorize-voter-checked` or
   `solana vote-authorize-withdrawer-checked` command with the following
   changes:

- the `--sign-only` argument is removed, and replaced with a `--signer` argument
  for each of the signatures provided by Entity B
- the address of Entity A's existing authority is replaced with the
  corresponding keypair, and the keypair for Entity B's new authority is
  replaced with the corresponding address

On success the authority is now changed without Entity A or B having to reveal
keypairs to the other even though both entities signed the transaction.

## Close a Vote Account

A vote account can be closed with the
`close-vote-account` command. Closing
a vote account withdraws all remaining SOL funds to a supplied recipient address
and renders it invalid as a vote account. It is not possible to close a vote
account with active stake.
