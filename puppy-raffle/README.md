# Puppy Raffle — Security Review

**Auditor:** Alejandro Betancourt
**Protocol:** Puppy Raffle — CodeHawks First Flight #1
**Date:** October 2026
**Commit hash:** `069cf56ec051216ccab79b550fba5e2a188ade9c`
**Repo:** https://github.com/Cyfrin/2023-10-Puppy-Raffle

## Scope

|              |                                       |
| ------------ | ------------------------------------- |
| Files        | `src/PuppyRaffle.sol`                 |
| nSLOC        | 143                                   |
| Solc         | 0.7.6                                 |
| Dependencies | OpenZeppelin v3.4.0, forge-std v1.5.6 |
| Chain        | Ethereum                              |

## Severity summary

| Severity | Count |
| -------- | ----- |
| High     | 2     |
| Medium   | —     |
| Low      | —     |
| Info     | —     |

## Findings

| ID                                         | Title                                                                     | Severity |
| ------------------------------------------ | ------------------------------------------------------------------------- | -------- |
| [H-01](findings/H-01-reentrancy-refund.md) | Reentrancy in `refund` allows draining the contract                       | High     |
| [H-02](findings/H-02-weak-randomness.md)   | Weak randomness in `selectWinner` makes winner and NFT rarity predictable | High     |

## Disclaimer

This review is a time-boxed security assessment of the code at the commit
above. It does not guarantee the absence of further vulnerabilities, and any
code changed after that commit is unreviewed.
