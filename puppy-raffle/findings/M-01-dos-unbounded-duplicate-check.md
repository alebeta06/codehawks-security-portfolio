# [M-01] Unbounded duplicate check in `enterRaffle` enables a denial of service

**Target:** `src/PuppyRaffle.sol` — `enterRaffle()`
**Severity:** Medium
**Status:** Confirmed with PoC

## Summary

`enterRaffle()` checks for duplicate players with a nested loop that compares
every player against every other. The cost grows quadratically with the number
of players already in the raffle, so each new entry becomes progressively more
expensive. Past a certain size, entering costs more gas than fits in a block,
making the raffle impossible to join.

## Root cause

The duplicate check iterates over the full `players` array for every new entry:

    for (uint256 i = 0; i < players.length - 1; i++) {
        for (uint256 j = i + 1; j < players.length; j++) {
            require(players[i] != players[j], "PuppyRaffle: Duplicate player");
        }
    }

The number of comparisons is proportional to `players.length²`. There is no
upper bound on how many players can enter, so the gas cost of `enterRaffle`
rises without limit as the array grows.

## Impact

- Entering the raffle becomes progressively more expensive for every new
  participant. Early entrants pay little; later entrants pay far more for the
  same action.
- Beyond a certain number of players, a single `enterRaffle` call exceeds the
  Ethereum block gas limit and can no longer be executed, locking out all
  further participation.
- An attacker can deliberately inflate the array with cheap early entries to
  push the cost beyond reach, denying entry to others and/or securing an
  advantage in a raffle they already joined.

## Proof of Concept

The following Foundry test enters two batches of 100 players each and measures
the gas of each `enterRaffle` call. The first batch enters an empty array; the
second batch enters when 100 players are already registered, and costs far more.

```solidity
function test_dos_entering_gets_more_expensive() public {
    uint256 groupSize = 100;

    address[] memory first = new address[](groupSize);
    for (uint256 i = 0; i < groupSize; i++) {
        first[i] = address(uint160(i + 1));
    }
    uint256 gasBefore1 = gasleft();
    puppyRaffle.enterRaffle{value: entranceFee * groupSize}(first);
    uint256 gasFirst = gasBefore1 - gasleft();

    address[] memory second = new address[](groupSize);
    for (uint256 i = 0; i < groupSize; i++) {
        second[i] = address(uint160(i + 1 + groupSize)); // 101..200
    }
    uint256 gasBefore2 = gasleft();
    puppyRaffle.enterRaffle{value: entranceFee * groupSize}(second);
    uint256 gasSecond = gasBefore2 - gasleft();

    assertGt(gasSecond, gasFirst);
}
```

Measured gas (per batch of 100 players):

```
first batch (empty array):       23,990,822
second batch (100 already in):    88,937,355   (~3.7x the first, and above the Ethereum block gas limit)
```

Result: `[PASS]`. Entering the same number of players costs ~3.7x more once the
array is populated, and the second batch alone exceeds the Ethereum block gas
limit — meaning that in production this entry could not be mined at all.

## Recommended mitigation

Remove the O(n²) duplicate check. Options:

- Track entrants with a `mapping(address => bool)` (or a per-raffle id) so
  duplicate detection is O(1) per entry instead of O(n²).
- Allow duplicates. A user can already enter from multiple wallets, so the
  check offers limited protection while introducing an unbounded gas cost.
- Use OpenZeppelin's `EnumerableSet` if set semantics are required.
