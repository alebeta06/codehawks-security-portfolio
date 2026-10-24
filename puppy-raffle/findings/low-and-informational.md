# Low, Informational & Gas Findings — Puppy Raffle

Secondary findings from the Puppy Raffle review. High and Medium findings are
documented separately. Items confirmed by static analysis (Slither / Aderyn)
are noted; the first was found only through manual review.

---

## [L-01] `getActivePlayerIndex` returns 0 for both the first player and "not found"

**Target:** `getActivePlayerIndex()`

`getActivePlayerIndex` returns `0` when a player is not in the array, but `0`
is also the valid index of the first player:

```solidity
function getActivePlayerIndex(address player) external view returns (uint256) {
    for (uint256 i = 0; i < players.length; i++) {
        if (players[i] == player) {
            return i;
        }
    }
    return 0; // same value as "player is at index 0"
}
```

A player sitting at index 0 cannot distinguish "I am the first player" from "I
am not registered." They may wrongly believe they are not in the raffle and
enter again, wasting the entrance fee.

**Recommendation:** revert when the player is not found, or return a sentinel
that cannot be a valid index (e.g. `int256(-1)`, or reserve index 0).

_Not flagged by Slither or Aderyn — found through manual review._

---

## [L-02] Strict balance equality in `withdrawFees` can be broken by forced ETH

**Target:** `withdrawFees()`

```solidity
require(address(this).balance == uint256(totalFees), "...");
```

A contract's balance can be forcibly increased by a `selfdestruct` that targets
this address, even though the contract has no `receive`/`fallback`. Once the
balance no longer equals `totalFees`, this strict equality never holds again
and the fees can never be withdrawn.

Note: this is a second, independent way to break the same `require` already
affected by the `totalFees` truncation (High finding). Both argue against
relying on `address(this).balance` as a source of truth.

**Recommendation:** avoid strict equality on `address(this).balance`. Track fees
with internal accounting and use `>=` if a balance check is needed.

_Confirmed by Slither (`incorrect-equality`) and Aderyn (H-4)._

---

## [L-03] Centralization: owner controls the fee address

**Target:** `changeFeeAddress()` / `feeAddress`

The owner can change `feeAddress` at any time. A compromised or malicious owner
redirects all protocol fees. The risk is documented and limited to fees (not
player funds), so severity is Low, but it should be disclosed.

**Recommendation:** document the trust assumption, and consider a timelock or
multisig for owner-only actions.

_Confirmed by Aderyn (L-1)._

---

## [I-01] Floating and outdated Solidity pragma

**Target:** line 2 — `pragma solidity ^0.7.6;`

The `^` allows any `0.7.x` compiler, so the deployed bytecode may differ from
what was tested. Additionally, 0.7.6 predates the automatic overflow/underflow
checks introduced in 0.8.0 — this directly enabled the `totalFees` truncation
(High finding).

**Recommendation:** pin an exact version and upgrade to a current 0.8.x release.

_Confirmed by Slither (`pragma`, `solc-version`) and Aderyn (L-11)._

---

## [I-02] Dead code: `_isActivePlayer` is never used

**Target:** `_isActivePlayer()`

The internal function `_isActivePlayer()` is never called anywhere in the
contract. Dead code increases surface area and audit noise.

**Recommendation:** remove it.

_Confirmed by Slither (`dead-code`) and Aderyn (L-3)._

---

## [G-01] Gas: `constant`/`immutable` and uncached array length

**Target:** state variables and loops

- `commonImageUri`, `rareImageUri`, `legendaryImageUri` are never reassigned and
  should be `constant`.
- `raffleDuration` is only set in the constructor and should be `immutable`.
- Loops read `players.length` from storage on every iteration; caching the
  length in a local variable saves gas.

**Recommendation:** apply `constant` / `immutable` where applicable and cache
`players.length` before loops.

_Confirmed by Slither (`constable-states`, `immutable-states`,
`cache-array-length`) and Aderyn (L-8, L-9, L-10)._
