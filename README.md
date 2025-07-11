Here is a full guide to deploying your `ERC20LotteryV2` contract and integrating it into your frontend app with `.env` configuration.

---

### ✅ 1. **Deploy the Contract (via Remix or Hardhat)**

#### Prerequisites:

* Token must be an ERC-20 token already deployed.
* Treasury address must be known.
* You must know the ticket price in whole tokens (e.g., `1 BBDOGE`).

#### Deploy Parameters:

| Param            | Description                                                       |
| ---------------- | ----------------------------------------------------------------- |
| `_token`         | The address of the ERC-20 token used for tickets (`BBDOGE` token) |
| `_treasury`      | Address to receive 20% of each entry                              |
| `_ticketCostTok` | Ticket price in whole tokens (e.g., `1` for 1 BBDOGE)             |

#### Example:

In **Remix** (Injected Provider):

```solidity
_token:      0xYourBBDOGEAddress
_treasury:   0xYourTreasuryAddress
_ticketCost: 1
```

Then click **Deploy**. Once deployed, note the **contract address**.

---

### ✅ 2. **Set Operator (Optional)**

After deployment, the **owner** can set a separate operator (e.g., your frontend admin wallet):

```solidity
function setOperator(address _operator) external onlyOwner
```

---

### ✅ 3. **Add the Contract Address to Your `.env`**

Create or edit your `.env` file:

```
VITE_LOTTERY_CONTRACT_ADDRESS=0xYourDeployedContractAddress
VITE_BBDOGE_TOKEN_ADDRESS=0xYourBBDOGEAddress
VITE_TREASURY_ADDRESS=0xYourTreasuryAddress
```

Ensure your frontend reads these like:

```ts
const LOTTERY_ADDRESS = import.meta.env.VITE_LOTTERY_CONTRACT_ADDRESS;
```

---

### ✅ 4. **Frontend Functionality for Owner**

Your DApp should expose the following **owner/admin functions**:

#### Boost Pool

```ts
await contract.boostPool(amountInUnits);
```

* Admin funds the prize pool with additional BBDOGE.

#### Pick Winner

```ts
await contract.pickWinner();
```

* Selects a winner based on weighted randomness.
* Transfers full pool to winner.
* Emits event and resets round.

#### Update Ticket Price

```ts
await contract.updateTicketCost(newPrice);
```

---

### ✅ 5. **How Randomness Works**

The contract uses:

```solidity
keccak256(abi.encodePacked(
  block.prevrandao,
  blockhash(block.number - 1),
  ticketsSold,
  address(this)
))
```

This provides **pseudo-randomness** without Chainlink VRF. It is acceptable for small or internal lotteries, but **not cryptographically secure** for large jackpots.

---

### ✅ 6. **User Ticket View (Frontend)**

You can call:

* `getPlayerTickets(address)`
* `getPlayers()`
* `playersCount()`
* `currentPool()`
* `ticketCostTokens()`

For better UX, display:

* How many tickets the user owns.
* The current round jackpot.
* Recent winner (`winners[gameId - 1]`).

---

### ✅ 7. **Basic Flow Diagram**

```txt
[User Buys Ticket] ---> enters --> [Lottery Contract]
    |                                      |
    +----> 80% to pool                     |
    +----> 20% to treasury                 |
                                           |
[Admin Picks Winner] ----> Transfers full pool to winner
```

---

Let me know if you'd like:

* A working frontend snippet to connect & call the contract
* A Hardhat script to deploy and verify on Basescan
* Styling or UI help for wallet actions

Ready to ship.
