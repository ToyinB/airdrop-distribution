# Airdrop Distribution Smart Contract

A comprehensive Stacks smart contract for secure token airdrop distribution with built-in safety mechanisms and administrative controls.

## Overview

This contract enables projects to distribute tokens through airdrops with precise control over eligibility, claim amounts, and time periods. It implements the SIP-010 fungible token standard and includes multiple safety features to prevent abuse.

## Key Features

- **SIP-010 Compatibility**: Works with any SIP-010 compliant fungible token
- **Flexible Distribution**: Set custom amounts per eligible address
- **Time-based Claims**: Configure claim periods with automatic expiration
- **Whitelist System**: Additional layer of access control
- **Safety Validations**: Multiple checks to prevent invalid operations
- **Emergency Controls**: Admin functions for crisis management

## Core Functions

### Administrative Functions

#### `set-token-contract(token)`
- Sets the fungible token contract for the airdrop
- Only callable by contract owner
- Validates token contract compatibility

#### `initialize-airdrop(total-amount, per-claim, period)`
- Initializes airdrop parameters
- `total-amount`: Total tokens allocated for distribution
- `per-claim`: Default tokens per claim transaction
- `period`: Claim period duration in blocks

#### `set-eligible-amount(address, amount)`
- Sets the total claimable amount for a specific address
- Allows different allocation amounts per user

### User Functions

#### `claim-airdrop(ft)`
- Claims tokens for eligible addresses
- Automatically validates eligibility and claim limits
- Transfers tokens using SIP-010 standard

### Query Functions

#### `get-claim-status(address)`
- Returns total amount already claimed by an address

#### `is-eligible(address)`
- Checks if an address is eligible for the airdrop

#### `get-airdrop-info()`
- Returns complete airdrop configuration and status

## Security Features

### Validation Checks
- **Amount Limits**: Min 1 token, max 1B tokens per operation
- **Address Validation**: Prevents contract and owner self-operations
- **Time Validation**: Enforces claim period restrictions
- **Token Verification**: Ensures only valid tokens are used

### Error Codes
- `u100`: Not authorized
- `u101`: Already claimed (also used for duplicate whitelist)
- `u102`: Not eligible
- `u103`: Wrong amount
- `u104`: Insufficient balance
- `u105`: Airdrop inactive
- `u106`: Token contract not set
- `u107`: Invalid token
- `u108`: Invalid amount
- `u109`: Invalid claim period
- `u110`: Invalid address

## Usage Example

```clarity
;; 1. Deploy the contract
;; 2. Set the token contract
(contract-call? .airdrop-contract set-token-contract .my-token)

;; 3. Initialize the airdrop
(contract-call? .airdrop-contract initialize-airdrop u10000000 u1000 u1000)

;; 4. Set eligible addresses
(contract-call? .airdrop-contract set-eligible-amount 'SP1... u5000)

;; 5. Users claim their tokens
(contract-call? .airdrop-contract claim-airdrop .my-token)
```

## Emergency Functions

### `end-airdrop()`
Immediately deactivates the airdrop, preventing further claims.

### `update-claim-period(new-end)`
Modifies the claim period end block (admin only).

### `emergency-withdraw(ft, amount)`
Allows contract owner to withdraw tokens in emergency situations.

## Best Practices

1. **Test Thoroughly**: Always test on testnet before mainnet deployment
2. **Validate Token**: Ensure your token contract is SIP-010 compliant
3. **Set Realistic Periods**: Consider network conditions for claim periods
4. **Monitor Claims**: Regularly check claim status and contract balance
5. **Emergency Planning**: Have procedures for using emergency functions

## Deployment Checklist

- [ ] Token contract is SIP-010 compliant
- [ ] Sufficient tokens deposited to contract
- [ ] Eligible addresses and amounts configured
- [ ] Claim period appropriately set
- [ ] Emergency procedures documented
- [ ] Contract tested on testnet

## Gas Considerations

- Token transfers consume gas based on SIP-010 implementation
- Batch operations for setting eligible addresses recommended
- Monitor contract balance for emergency withdrawals

## Support

This contract provides a robust foundation for token airdrops on Stacks. Ensure thorough testing and consider professional audit for high-value distributions.
