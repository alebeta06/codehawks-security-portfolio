# [H-01] Reentrancy in `refund` allows draining the contract

**Target:** `src/PuppyRaffle.sol` — `refund()`
**Severity:** High
**Status:** Root cause identified — PoC pending

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

## Impact

Complete loss of contract funds. Any player can steal all ETH held by the raffle.

## Recommended mitigation

Apply CEI — update state before the external call:

    players[playerIndex] = address(0);
    emit RaffleRefunded(playerAddress);
    payable(msg.sender).sendValue(entranceFee);

Optionally add a `nonReentrant` modifier (OpenZeppelin `ReentrancyGuard`) as
defense in depth.

## PoC

_Pending — to be added: Foundry test with an attacker contract that re-enters
`refund()` via `receive()` and drains the balance._
