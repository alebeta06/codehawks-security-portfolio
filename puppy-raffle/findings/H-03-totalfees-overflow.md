# [H-03] `uint64` truncation of `totalFees` permanently locks protocol fees

**Target:** `src/PuppyRaffle.sol` — `selectWinner()` / `withdrawFees()`
**Severity:** High
**Status:** Confirmed with PoC

## Summary

`totalFees` is stored as a `uint64`. When a raffle's fee exceeds
`type(uint64).max` (~18.44 ETH), the conversion `uint64(fee)` silently
truncates the value. `totalFees` ends up far smaller than the fees actually
collected, and because `withdrawFees()` requires an exact match between the
contract balance and `totalFees`, the protocol fees become permanently locked.

## Root cause

The fee accumulator is a `uint64`, and each raffle adds its fee through a
narrowing cast:

    uint64 public totalFees = 0;
    ...
    totalFees = totalFees + uint64(fee);

The failure is in the cast `uint64(fee)`, not in the addition. `fee` is a
`uint256` equal to 20% of the pot. With 93 players at a 1 ETH entrance fee, the
pot is 93 ETH and the fee is 18.6 ETH (18.6e18 wei) — already larger than
`type(uint64).max` (18446744073709551615 ≈ 18.44e18). Forcing that value into a
`uint64` truncates it to ~0.15 ETH.

Solidity 0.7.6 performs no automatic overflow checks, and a narrowing cast
truncates silently — no revert, no warning. A single large raffle is enough to
trigger it; the fees do not need to accumulate across rounds.

## Impact

The bug corrupts the fee accounting and then locks the funds:

1.  After a 93-player raffle, `totalFees` records ~0.15 ETH while 18.6 ETH in
    fees were actually collected.
2.  `withdrawFees()` enforces:

        require(address(this).balance == uint256(totalFees), "...");

    The real balance (18.6 ETH in fees) never equals the truncated `totalFees`
    (0.15 ETH), so the `require` always fails and the call reverts.

3.  The protocol's fees are **permanently locked** in the contract. There is no
    code path to recover them.

Note: reaching this number of players also exposes the unbounded duplicate
check in `enterRaffle` (a DoS, reported separately), observed here as ~19M gas
for a single entry call.

## Recommended mitigation

- Store `totalFees` as a `uint256` — this removes the truncation entirely.
- Upgrade to Solidity ≥ 0.8 so arithmetic and casts are checked, as defense in
  depth.
- Reconsider the strict-equality `require` in `withdrawFees()`. It is also
  fragile against forced ETH via `selfdestruct` (a separate finding), and an
  internal fee accounting that does not depend on `address(this).balance` would
  be more robust.

## Proof of Concept

The following Foundry test enters 93 players, runs the draw, and shows that the
recorded `totalFees` is far smaller than the real fees (truncation), and that
`withdrawFees()` then reverts (locked funds). The full, runnable PoC lives in
the scope repository; the files under `poc/` are included here as reference and
do not compile standalone.

```solidity
function test_fee_overflow_locks_withdrawals() public {
    uint256 playerCount = 93;
    address[] memory players = new address[](playerCount);
    for (uint256 i = 0; i < playerCount; i++) {
        players[i] = address(uint160(i + 1));
    }
    puppyRaffle.enterRaffle{value: entranceFee * playerCount}(players);

    vm.warp(block.timestamp + duration + 1);
    puppyRaffle.selectWinner();

    uint256 feesRecorded = puppyRaffle.totalFees();
    uint256 feesExpected = (entranceFee * playerCount * 20) / 100; // 18.6 ETH, the real fees
    assertLt(feesRecorded, feesExpected); // recorded << real: truncation happened

    vm.expectRevert("PuppyRaffle: There are currently players active!");
    puppyRaffle.withdrawFees();
}
```

The execution trace confirms both the truncation and the lock:

```
├─ PuppyRaffle::selectWinner()
│   ├─ 0x52::fallback{value: 74400000000000000000}()   ← 74.4 ETH to the winner (prize is fine)
├─ PuppyRaffle::totalFees() → 153255926290448384       ← 0.15 ETH recorded (should be 18.6)
├─ PuppyRaffle::withdrawFees()
│   └─ ← [Revert]                                       ← fees locked
```

Result: `[PASS]`. `totalFees` is truncated to ~0.15 ETH instead of 18.6 ETH,
and the subsequent `withdrawFees()` call reverts, confirming the fees are
unrecoverable.

## References

- SWC-101: Integer Overflow and Underflow
- Cyfrin `sc-exploits-minimized` — arithmetic (overflow / unsafe cast) example
