# [H-02] Weak randomness in `selectWinner` — winner and NFT rarity are predictable

**Target:** `src/PuppyRaffle.sol` — `selectWinner()`
**Severity:** High
**Status:** Confirmed with PoC

## Summary

`selectWinner()` derives both the raffle winner and the NFT rarity from
on-chain values (`msg.sender`, `block.timestamp`, `block.difficulty`). These
values are known or controllable at transaction time, so there is no real
randomness: an attacker can compute the outcome off-chain in advance and only
submit the transaction when it favors them.

## Root cause

On-chain data is deterministic — every node must reach the same result — so it
cannot be a source of secure randomness. Two lines rely on it:

Winner selection:

    uint256 winnerIndex = uint256(keccak256(abi.encodePacked(
        msg.sender, block.timestamp, block.difficulty))) % players.length;

NFT rarity:

    uint256 rarity = uint256(keccak256(abi.encodePacked(
        msg.sender, block.difficulty))) % 100;

Every input is predictable or attacker-controlled: `msg.sender` is the
attacker's own address, `block.timestamp` is predictable and can be nudged by
a validator, and `block.difficulty` (now `prevrandao`) is known to the block
proposer. The attacker reproduces the `keccak256` computation off-chain and
submits the call only in a block where the result makes them win or mints the
rarest NFT.

In addition, `selectWinner()` has no access control: it is `external` and
anyone can call it once the raffle duration has elapsed. This lets the attacker
choose **when and under what block conditions** the draw executes, rather than
leaving it to chance. Combined with the predictable entropy, the attacker
computes in advance the block values that make them win and only executes when
those conditions are met.

## Impact

An attacker can guarantee they win the raffle and/or mint the legendary NFT at
will, removing all fairness from the protocol and stealing value from honest
participants. Both the prize and the rarity distribution become fully
attacker-controlled.

## Recommended mitigation

Do not derive randomness from on-chain values — adding more of them does not
help, since all remain predictable. Use a verifiable randomness oracle such as
Chainlink VRF, which delivers a random number together with a cryptographic
proof that it was not manipulated by any party (miner, validator, or caller).

Access control on `selectWinner()` would not fix the randomness itself, but it
reduces the attacker's ability to choose the execution moment and should be
considered as a complementary measure.

## Proof of Concept

The following Foundry test shows that an attacker can **force their own win**.
They enter the raffle, compute off-chain which `block.difficulty` value makes
`selectWinner()`'s `keccak256` resolve to their index, set that value, and
execute the draw. There is no randomness — the outcome is chosen in advance.
The full, runnable PoC lives in the scope repository; the files under `poc/`
are included here as reference and do not compile standalone.

```solidity
function test_weak_randomness_attacker_wins() public {
    address attacker = makeAddr("attacker");
    address[] memory newPlayers = new address[](1);
    newPlayers[0] = attacker;
    puppyRaffle.enterRaffle{value: entranceFee}(newPlayers);

    uint256 attackerIndex = puppyRaffle.getActivePlayerIndex(attacker);
    vm.warp(block.timestamp + duration + 1);

    uint256 numPlayers = 5; // 4 from setUp + attacker
    uint256 winningDifficulty;
    bool found;

    // All RNG inputs are known before the call, so the attacker can
    // brute-force a block.difficulty value that makes them win.
    for (uint256 d = 0; d < 100; d++) {
        uint256 predictedIndex = uint256(
            keccak256(abi.encodePacked(attacker, block.timestamp, d))
        ) % numPlayers;
        if (predictedIndex == attackerIndex) {
            winningDifficulty = d;
            found = true;
            break;
        }
    }
    assertTrue(found);

    vm.difficulty(winningDifficulty);

    // selectWinner has no access control: anyone can trigger the draw.
    vm.prank(attacker);
    puppyRaffle.selectWinner();

    assertEq(puppyRaffle.previousWinner(), attacker);
}
```

The execution trace confirms the attack: the attacker finds that
`difficulty = 5` makes them win, and on executing the draw receives the prize
(4 ETH, 80% of the pot) and the NFT:

```
├─ VM::difficulty(5)                                        ← attacker-chosen value
├─ VM::prank(attacker)
├─ PuppyRaffle::selectWinner()
│   ├─ attacker::fallback{value: 4000000000000000000}()     ← 4 ETH to attacker
│   ├─ emit Transfer(from: 0x0, to: attacker, tokenId: 0)   ← NFT to attacker
├─ PuppyRaffle::previousWinner() → attacker                 ← attacker wins
```

Result: `[PASS]`. The attacker picks the block value that makes them win,
triggers the draw with no access restriction, and takes both the prize and the
NFT. The outcome was never random.

## References

- SWC-120: Weak Sources of Randomness from Chain Attributes
- Cyfrin `sc-exploits-minimized` — weak randomness example
