# CodeHawks Security Portfolio

This repository contains my portfolio of smart contract security audits completed as part of the [Cyfrin Updraft Smart Contract Security Auditor program](https://github.com/Cyfrin/security-and-auditing-full-course-s23?tab=readme-ov-file#%EF%B8%8F-section-3-your-first-audit-security-review--passwordstore-audit).

## About

- 📚 Here I will document all my audit reports, findings, and learning progress as I advance through the Updraft program by Cyfrin.
- 🛡️ Each audit report is a real exercise on smart contract security, covering vulnerabilities, best practices, and recommendations.

## First Audit: Password Store

[2025-7-3-passwordstore-audit.pdf](https://github.com/alebeta06/codehawks-security-portfolio/blob/main/2025-7-3-passwordstore-audit.pdf)
- My first audit, focused on a simple password storage contract. I identified critical issues such as lack of access control and on-chain secret exposure.

https://github.com/Cyfrin/3-passwordstore-audit

## Second Audt: Puppy Raffle

[2025-7-23-puppyraffle-audit.pdf](https://github.com/alebeta06/codehawks-security-portfolio/blob/main/2025-7-23-puppyraffle-audit.pdf)
- This project is to enter a raffle to win a cute dog NFT. The protocol should do the following:

1. Call the `enterRaffle` function with the following parameters:
   1. `address[] participants`: A list of addresses that enter. You can use this to enter yourself multiple times, or yourself and a group of your friends.
2. Duplicate addresses are not allowed
3. Users are allowed to get a refund of their ticket & `value` if they call the `refund` function
4. Every X seconds, the raffle will be able to draw a winner and be minted a random puppy
5. The owner of the protocol will set a feeAddress to take a cut of the `value`, and the rest of the funds will be sent to the winner of the puppy.

https://github.com/Cyfrin/4-puppy-raffle-audit

## More coming soon!

Follow my journey as I grow as a Web3 security auditor.

---

Este repositorio documenta mi progreso y aprendizaje en seguridad de smart contracts con Cyfrin Updraft.
