# Gas Fee Optimizer: Meta-Transactions & Batched Relayer

## Overview
This project tackles one of the most significant barriers to Web3 adoption: network congestion and high execution costs. By combining off-chain cryptography with on-chain batched processing, this architecture allows secondary users to interact with smart contracts without holding native network tokens to pay for gas.

This repository contains a fully functional, production-mimicking prototype deployed on the Sepolia Testnet, complete with an off-chain frontend gatekeeper and an optimized Solidity smart contract.

---

## Core Architecture & Gas Savings

### Pillar 1: Meta-Transactions (EIP-712)
Traditionally, the `msg.sender` in Ethereum is the address that pays the gas fee. This system decouples the *signer* from the *sender* using **Meta-Transactions**.
* Users generate cryptographic signatures off-chain using the EIP-712 standard, mathematically locking their "intent" (recipient, amount, and nonce) to a specific Domain Separator.
* Because signing a message requires no blockchain interaction, the user pays absolutely nothing.
* The Smart Contract utilizes `ecrecover` to cryptographically verify that the user explicitly authorized the transfer of their internally deposited funds.

### Pillar 2: Batched Execution (The Gas Optimizer)
Every standard Ethereum transaction requires a base fee of 21,000 gas, regardless of how small the transaction is. If 10 users send 10 separate transactions, the network charges a minimum of 210,000 gas. 

This architecture introduces a **Gas Relayer**. The Relayer bundles multiple signed intents into a single array and submits them to the `executeBatch` function. 

**The Mathematical Advantage:**
By processing everything in a single loop, the Relayer only pays the 21,000 base gas limit *once* for the entire batch. The only additional cost per user is the operational gas required to execute the loop logic and update the internal ledger. 

### Demonstrated Savings
During live network testing on the Sepolia Testnet, this architecture achieved the following results:
- **Traditional Model:** 5 users sending separate transactions = ~105,000 base gas.
- **Relayer Model:** 5 users bundled in one transaction = 21,000 base gas + loop execution costs.
- **User Cost:** Secondary users retained 100% of their ETH, experiencing a completely gasless environment. 

---

## Security & Architecture Trade-offs

### 1. Deterministic Execution vs. Optimistic UX
A core design choice in this GasRelayer architecture is the strict enforcement of a **1-Transaction-Per-User** rule per batch. 

To prevent Replay Attacks, the smart contract utilizes an internal `nonces[user]` mapping. Every EIP-712 signature mathematically locks in the user's current on-chain nonce. Once a batch is executed, the contract strictly increments this nonce (`nonces[user]++`) before accepting a new signature from that same address. 

**The Trade-off:**
We prioritized mathematical security and deterministic execution over "power user" convenience. By forcing the frontend to read the *confirmed* on-chain nonce rather than predicting it off-chain, we guarantee that every transaction in the batch evaluates independently. 

### 2. Avoiding "Nonce Gridlock" 
In a highly active system, a user might want to submit multiple transactions into the same batch queue rapidly. To allow this, the frontend would need an "Optimistic Nonce Cache" to artificially increment nonces locally. 

While this improves User Experience (UX), it introduces a critical fragility known as **Nonce Gridlock**: If the first transaction in an optimistic chain is dropped or reverts, every subsequent transaction from that user instantly becomes invalid because the on-chain nonce never updated. By restricting the prototype to deterministic on-chain nonces, we completely eliminate these cascading failures.

### 3. The Off-Chain Gatekeeper
To prevent the Relayer from wasting gas on transactions that will inevitably fail on-chain, the frontend UI implements an off-chain gatekeeper. Before the Relayer submits the batch, the JavaScript layer queries the smart contract's `balances` mapping for every user in the queue. Any user with insufficient funds is cleanly sliced out of the batch array, ensuring the Relayer only pays for mathematically sound intents.

---

## Repository Structure

```text
GAS-OPTIMIZATION-BLOCKCHAIN
|
├── contracts/
│   └── GasRelayerSecure.sol       # The core EIP-712 and Batching logic
│
├── frontend/
│   └── batch-demo.html            # The unified HTML/JS Relayer dashboard
│── Kriti Report.pdf
└── README.md                      # Architecture documentation
