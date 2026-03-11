<div align="center">
  <h1>⛽ Gas Fee Optimizer</h1>
  <p><b>Zero-Gas Meta-Transactions & Batched Relayer Architecture</b></p>
  
  [![Live Demo](https://img.shields.io/badge/Live_Demo-gas--optimization--blockchain.vercel.app-blue?style=for-the-badge)](https://gas-optimization-blockchain.vercel.app)
  [![Network](https://img.shields.io/badge/Network-Sepolia_Testnet-lightgrey?style=for-the-badge)]()
</div>

<br>

## 🚀 Introduction
Network congestion and the flat 21,000 EVM base gas limit create massive friction for decentralized applications. This project bypasses this barrier by decoupling the transaction *signer* from the *broadcaster*. Secondary users can interact with the smart contract without holding any native ETH, while a central Relayer optimizes network fees through batch execution.

## 🛠 Tech Stack
* **Smart Contracts:** Solidity `^0.8.19`, OpenZeppelin (`EIP712`, `ECDSA`)
* **Frontend:** HTML5, Vanilla JavaScript, CSS
* **Web3 Connectivity:** Ethers.js, MetaMask
* **Deployment & Hosting:** Sepolia Testnet, Vercel

---

## 🧠 What I Did & Why

**1. Implemented EIP-712 Meta-Transactions (Off-Chain Cryptography)**
* **What:** Users sign a structured data payload (`MetaTransaction`) containing the recipient, amount, and nonce, rather than submitting a standard transaction.
* **Why:** Cryptographic signatures require zero blockchain interaction. This allows users to authorize internal ledger transfers with **$0.00 gas fees**.

**2. Built a Batched Gas Relayer (On-Chain Execution)**
* **What:** A single Relayer account bundles multiple off-chain signatures into arrays and submits them to the `executeBatch` smart contract function.
* **Why:** The EVM charges a flat 21,000 gas limit per transaction. By looping through an array of intents in one transaction, the Relayer pays that base fee *once* for the entire batch, yielding massive collective gas savings.

**3. Engineered an Off-Chain Gatekeeper**
* **What:** The JavaScript frontend verifies user balances before allowing the Relayer to submit the batch.
* **Why:** Prevents the Relayer from wasting gas on transactions mathematically guaranteed to fail on-chain.

---

## 🏗 System Architecture


```text
  [User 1] --(Signs Intent)--> \
  [User 2] --(Signs Intent)-->  |--> [ JavaScript Gatekeeper ] 
  [User 3] --(Signs Intent)--> /          (Pre-flight checks)
                                                  |
                                                  v
                                      [ Relayer / Account 1 ]
                                      (Pays 1x Base Gas Fee)
                                                  |
                                                  v
                                     [ EVM Smart Contract ]
                                 (ecrecover -> updates ledger)

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
│── GAS-OPTIMIZATION.pdf
└── README.md                      # Architecture documentation
