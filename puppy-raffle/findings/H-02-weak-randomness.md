# [H-02] Weak randomness in `selectWinner` — winner and NFT rarity are predictable

**Target:** `src/PuppyRaffle.sol` — `selectWinner()`
**Severity:** High
**Status:** Root cause identified — PoC pending

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

## PoC

_Pending — to be added: Foundry test showing that the winner/rarity outcome can
be computed off-chain and reproduced on-chain, letting the attacker win
deterministically._

## References

- SWC-120: Weak Sources of Randomness from Chain Attributes
- Cyfrin `sc-exploits-minimized` — weak randomness example
