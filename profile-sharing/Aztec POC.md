# Private Profile Application on Aztec: Product Requirements Document (PRD)

**Version:** 1.0  
**Date:** September 12, 2025  
**Author:** Jaswinder Singh
**Purpose:** This document outlines the high-level requirements for a private profile application built on the Aztec zkRollup. It serves as a shareable reference for the development team and discussions with the Aztec team. Focus areas include profile creation, sharing, user flows, PXE integration, encryption/decryption mechanics, and estimated costs. This is not a formal PRD but a structured overview to guide implementation.

## 1. Product Overview
The Private Profile App is a decentralized application (dApp) leveraging Aztec's privacy-first zkRollup on Ethereum. It allows users to create, update, and share personal profiles (e.g., name, bio, age, preferences) in a fully private manner using Aztec's "notes" (encrypted UTXOs). Unlike public blockchains, all profile data remains encrypted and client-side, visible only to the owner or authorized recipients.

**Key Goals:**
- Enable privacy-preserving personal data management for use cases like social networking, dating, or professional profiles.
- Demonstrate Aztec's strengths in private state management.
- Ensure low-friction user experience similar to Web2 apps, with backend privacy via zk-proofs.

**Target Users:** Individuals seeking private data sharing; developers exploring Aztec for privacy apps.

**Assumptions:**
- Built using Aztec.nr for smart contracts and Aztec.js for frontend integration.
- Aztec Network is in its Adversarial Testnet phase as of September 2025, with full mainnet expected soon.
- No reliance on centralized servers; all privacy-critical ops are client-side.

## 2. Key Features
### 2.1 Profile Creation
- **Description:** Users create a private profile stored as an encrypted note (UTXO). The profile includes customizable fields (e.g., name as [u8;32], bio as [u8;128], age as u8).
- **Requirements:**
  - Triggered via a private function in the Aztec.nr contract.
  - No parent note required—new notes can be minted freely (unlike Bitcoin UTXOs).
  - Profile is owned by the creator's AztecAddress by default.
  - Optional: Validation rules (e.g., age > 18) enforced in contract logic.
- **Privacy Aspect:** Data is encrypted on creation; only the commitment (hash) is posted on-chain.

### 2.2 Profile Sharing
- **Description:** Users share profiles privately by creating a new note with the recipient as the owner, embedding the profile data.
- **Requirements:**
  - Sender specifies recipient's AztecAddress.
  - Creates a fresh note (not a transfer—optionally keep a copy by minting two notes).
  - Sharing methods:
    - On-chain: Emit encrypted logs for recipient discovery.
    - Off-chain: Direct encrypted data transfer (e.g., via app messaging).
  - Recipient gains ownership: Can view, update, or re-share.
- **Privacy Aspect:** Encrypted to recipient's keys; sender signs the transaction, but data remains private.

### 2.3 Profile Updating
- **Description:** Owners update profiles by nullifying (spending) the old note and creating a new one.
- **Requirements:** Private function that proves ownership via note pre-image, computes nullifier, and inserts new note.

### 2.4 Viewing Profiles
- **Description:** Off-chain query for own or received profiles.
- **Requirements:** Utility function in contract for local reads; no transaction needed.

## 3. User Flows
### 3.1 End-User Flow for Profile Creation
1. User connects wallet (e.g., via Aztec-enabled extension) and authenticates account.
2. In the app UI, user enters profile details (name, bio, etc.).
3. App calls private contract function via Aztec.js.
4. PXE (client-side) generates zk-proof, signs tx, and submits to Aztec sequencer.
5. Tx confirms: Note commitment on-chain; encrypted data stored in user's PXE.
6. User sees confirmation; profile viewable locally.

### 3.2 End-User Flow for Profile Sharing
1. User selects a profile to share and enters recipient's AztecAddress (e.g., via QR code or search).
2. App creates new note with recipient as owner.
3. PXE executes private function: Generates proof, signs tx.
4. Tx submits: Encrypted log emitted (or off-chain send).
5. Recipient's PXE discovers/scans for the note (auto-synced from chain).
6. Recipient decrypts and views in their app; now owns the note.

### 3.3 End-User Flow for Viewing/Updating
1. User opens app; PXE queries local database for owned notes.
2. App decrypts and displays profile.
3. For update: User edits fields; app nullifies old note, creates new one via private tx.

**Overall UX Notes:** Flows mimic Ethereum dApps (e.g., MetaMask prompts), but with added privacy. No gas estimates shown upfront; app handles retries.

## 4. Technical Architecture
### 4.1 Private Execution Environment (PXE)
- **Overview:** Client-side runtime for private ops, running in browser/Node.js (no central server).
- **Role in App:**
  - Stores encrypted notes and keys locally (e.g., IndexedDB).
  - Executes private functions, generates zk-proofs.
  - Handles note discovery (scans encrypted logs).
  - Oracles for injecting private data into circuits without exposure.
- **Integration:** Use Aztec.js to interface with PXE; ensures data never leaves user's device.

### 4.2 Encryption/Decryption Flow
- **Encryption (Creation/Sharing):**
  1. App packs profile data into note struct.
  2. Note encrypted using recipient's public keys (derived from AztecAddress).
  3. Commitment (Poseidon2 hash of note + storage slot) inserted into note hash tree.
- **Decryption (Viewing):**
  1. PXE retrieves encrypted note (from local DB or discovered log).
  2. Uses owner's private keys to decrypt pre-image.
  3. App unpacks fields for display.
- **Nullification (Updating/Spent):** Owner proves knowledge of pre-image + secret; computes nullifier hash to mark as spent.
- **Security:** Zero-knowledge proofs verify ops without revealing data; based on Aztec's UTXO model.

**Contract Snippet Example (Aztec.nr):**
```rust
#[note]
struct ProfileNote {
    name: [u8; 32],
    bio: [u8; 128],
    age: u8,
    owner: AztecAddress,
}

#[private]
fn share_profile(recipient: AztecAddress, /* profile data */) {
    // Create and insert new note; emit encrypted log
}
```

## 5. Costs and Economics
- **Transaction Fees:** Aztec uses "mana" as a gas equivalent and "fee-juice" for payments, with low costs due to zk-batching. As of 2025, typical private txs cost a few cents (e.g., minimal per tx on testnet/mainnet), far below Ethereum L1 fees. Creation/sharing incurs one tx; viewing is off-chain (free).
- **Breakdown:**
  - Profile Creation/Sharing/Update: ~0.01-0.05 USD per tx (estimated; varies with Ethereum gas).
  - No fees for off-chain shares or local views.
- **Payment Options:** Pay with ETH or tokens; abstracted in app.
- **Notes:** Costs may fluctuate; monitor Aztec's Adversarial Testnet for 2025 benchmarks. App could subsidize initial txs for onboarding.

## 6. Risks and Next Steps
**Risks:**
- Testnet instability (e.g., sequencer decentralization in progress).
- User education on privacy (e.g., key management).
- Integration bugs with PXE/Aztec.js.

**Next Steps:**
- Prototype contract in Aztec sandbox.
- UI mockups for flows.
- Call with Aztec team: Discuss PXE optimizations, fee models.
- Timeline: MVP in 4-6 weeks.
