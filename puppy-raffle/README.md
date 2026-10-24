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

| Severity   | Count |
| ---------- | ----- |
| High       | 3     |
| Medium     | 1     |
| Low        | 3     |
| Info / Gas | 3     |

## Findings

| ID                                                                                                                    | Title                                                                      | Severity |
| --------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------- | -------- |
| [H-01](findings/H-01-reentrancy-refund.md)                                                                            | Reentrancy in `refund` allows draining the contract                        | High     |
| [H-02](findings/H-02-weak-randomness.md)                                                                              | Weak randomness in `selectWinner` makes winner and NFT rarity predictable  | High     |
| [H-03](findings/H-03-totalfees-overflow.md)                                                                           | `uint64` truncation of `totalFees` permanently locks protocol fees         | High     |
| [M-01](findings/M-01-dos-unbounded-duplicate-check.md)                                                                | Unbounded duplicate check in `enterRaffle` enables a denial of service     | Medium   |
| [L-01](findings/low-and-informational.md#l-01-getactiveplayerindex-returns-0-for-both-the-first-player-and-not-found) | `getActivePlayerIndex` returns 0 for both the first player and "not found" | Low      |
| [L-02](findings/low-and-informational.md#l-02-strict-balance-equality-in-withdrawfees-can-be-broken-by-forced-eth)    | Strict balance equality in `withdrawFees` can be broken by forced ETH      | Low      |
| [L-03](findings/low-and-informational.md#l-03-centralization-owner-controls-the-fee-address)                          | Centralization: owner controls the fee address                             | Low      |
| [I-01 / I-02 / G-01](findings/low-and-informational.md)                                                               | Floating pragma, dead code, and gas optimizations                          | Info/Gas |

## Tooling

Manual review first, then static analysis with Slither and Aderyn to validate
findings and surface mechanical issues. The High-severity logic bugs — in
particular the `totalFees` truncation (H-03) — were found through manual review
and not flagged by either tool.

## Disclaimer

This review is a time-boxed security assessment of the code at the commit
above. It does not guarantee the absence of further vulnerabilities, and any
code changed after that commit is unreviewed.
