# Cross-chain Bridge Contract

This Clarity smart contract facilitates cross-chain asset transfers with a focus on security and flexibility. It introduces key improvements over the previous version, including support for multiple tokens and a fee mechanism.

## Key Features:

* **Multi-Token Support:** The contract now supports bridging operations for various fungible tokens, not just STX.  This is managed through a registry of supported tokens, allowing for extensibility and integration with diverse assets.
* **Fee Mechanism:** A configurable fee, expressed in basis points (BPS), is now applied to each bridge transaction. This fee is collected by the contract owner and can be adjusted as needed.
* **Enhanced Security:**  The contract includes rigorous checks to prevent unauthorized access, invalid transactions, and double-spending. It also handles potential failures gracefully, allowing users to claim or refund their assets in case of incomplete operations.
* **Improved Error Handling:** More specific error codes have been introduced to provide better feedback and facilitate debugging.
* **Admin Functions:**  The contract owner can pause/unpause the bridge, set the minimum deposit amount, transfer ownership, and manage the list of supported tokens.

## Contract Upgrade Details:

Here's a summary of the changes introduced in this version compared to the previous one:

| Feature | Old Contract | New Contract |
|---|---|---|
| Token Support | Only STX | Multiple fungible tokens via `ft-trait` |
| Fee Mechanism | None | Configurable fee in BPS |
| `bridge-requests` Map | `{ tx-id, amount, recipient }` | `{ tx-id, token, amount, recipient }` |
| `balances` Map | `principal -> uint` | `{ token: principal, user: principal } -> uint` |
| `processed-txs` Map | Exists | Exists |
| `claims` Map | `principal -> uint` | `{token: principal, user: principal} -> uint` |
| Error Handling | Basic error codes | More granular error codes for improved debugging |
| Supported Tokens | N/A | Managed via `supported-tokens` map and admin functions |


## Usage:

### Initializing a Bridge Request:

Users initiate a bridge request by calling the `initialize-bridge-request` function, providing the transaction ID, the desired token, amount, and recipient.  The contract validates the request, deducts the tokens from the user's balance, and records the request details.

### Completing a Bridge Operation:

The contract owner completes the bridge operation by calling the `complete-bridge-operation` function, providing the transaction ID, token, amount, and recipient.  The contract verifies the request details, calculates and deducts the fee, and transfers the remaining amount to the recipient.

### Handling Failed Bridge Operations:

Users can claim their assets back after a timeout period using the `claim-failed-bridge` function if the bridge operation fails. The contract owner can also refund the assets using the `refund-failed-bridge` function.

### Admin Functions:

The contract owner has access to several admin functions:

* `set-paused`: Pauses or unpauses the bridge.
* `set-minimum-amount`: Sets the minimum deposit amount.
* `transfer-ownership`: Transfers ownership of the contract to a new principal.
* `add-supported-token`: Adds a new fungible token to the list of supported tokens.
* `remove-supported-token`: Removes a fungible token from the list of supported tokens.


## Development:

The contract is written in Clarity and can be deployed on the Stacks blockchain.  See the accompanying test suite for examples of how to interact with the contract.
