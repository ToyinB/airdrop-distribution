# Clarity Airdrop Distribution Smart Contract

## Overview
A Clarity smart contract for managing token airdrops on the Stacks blockchain. Features automated distribution, whitelist management, claim tracking, and security controls.

## Key Features
- Automated token distribution
- Whitelist management
- Claim period controls
- Flexible allocation amounts
- Security controls and emergency functions

## Contract Functions

### Admin Functions
```clarity
(initialize-airdrop total-amount per-claim period)
(add-to-whitelist address)
(set-eligible-amount address amount)
(end-airdrop)
```

### User Functions
```clarity
(claim-airdrop)
(get-claim-status address)
(is-eligible address)
```

### Emergency Functions
```clarity
(emergency-withdraw token-contract amount)
(update-claim-period new-end)
```

## Quick Start

1. **Deploy Contract**
   ```bash
   # Deploy using Clarinet or Stacks CLI
   ```

2. **Initialize Airdrop**
   ```clarity
   (initialize-airdrop u1000000 u100 u1000)
   ```

3. **Set Eligible Addresses**
   ```clarity
   (set-eligible-amount address u1000)
   ```

4. **Users Claim Tokens**
   ```clarity
   (claim-airdrop)
   ```

## Error Codes
- `ERR-NOT-AUTHORIZED (u100)`: Unauthorized access
- `ERR-NOT-ELIGIBLE (u102)`: Address not eligible
- `ERR-INSUFFICIENT-BALANCE (u104)`: Not enough tokens
- `ERR-AIRDROP-INACTIVE (u105)`: Airdrop ended/paused

## Security Features
- Owner-only administrative functions
- Balance verification
- Double-claim prevention
- Emergency controls
- Time-bound operations

## Requirements
- Stacks blockchain node
- Clarity CLI tools
- Token contract for distribution
