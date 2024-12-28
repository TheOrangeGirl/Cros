# Cros Bridge

A secure cross-chain bridge enabling asset transfers between Bitcoin and Stacks blockchain networks.

## Features

- Secure asset transfer between Bitcoin and Stacks networks
- Automated verification and settlement
- Liquidity pools managed through Clarity smart contracts
- Admin controls for security management
- Built-in pause mechanism for emergency situations

## Smart Contract Functions

### User Functions

- `initialize-bridge-request`: Start a bridge transfer
- `get-balance`: Check user balance
- `complete-bridge-operation`: Complete a bridge transfer (admin only)

### Admin Functions

- `set-paused`: Pause/unpause bridge operations
- `transfer-ownership`: Transfer contract ownership

## Error Codes

- `ERR_UNAUTHORIZED (u1)`: Unauthorized operation
- `ERR_INVALID_AMOUNT (u2)`: Invalid transfer amount
- `ERR_INSUFFICIENT_BALANCE (u3)`: Insufficient balance
- `ERR_PAUSED (u4)`: Bridge operations paused
- `ERR_INVALID_OPERATION (u5)`: Invalid bridge operation

## Security

- Minimum deposit requirement
- Owner-only administrative functions
- Emergency pause mechanism
- Transaction verification

## Development

1. Install Clarinet
2. Deploy using:
```bash
clarinet contract deploy cros
```

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit changes
4. Push to branch
5. Create Pull Request