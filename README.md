# Cros Bridge

A secure cross-chain bridge enabling asset transfers between Bitcoin and Stacks blockchain networks.

## Features

- Secure asset transfer between Bitcoin and Stacks networks
- Real-time analytics and volume tracking
- Automated verification and settlement
- Liquidity pools managed through Clarity smart contracts
- Admin controls for security management
- Built-in pause mechanism for emergency situations
- Daily volume tracking and user statistics

## Smart Contract Functions

### User Functions

- `initialize-bridge-request`: Start a bridge transfer
- `validate-and-record-bridge`: Validate and initiate a bridge transfer with stats recording
- `claim-failed-bridge`: Claim funds from failed bridge operations
- `refund-failed-bridge`: Get refund for failed transfers
- `get-balance`: Check user balance
- `get-bridge-metrics`: View current bridge statistics
- `get-user-bridge-stats`: Get user-specific bridge metrics

### Admin Functions

- `complete-bridge-operation`: Complete a bridge transfer
- `batch-process-claims`: Process multiple refund claims
- `emergency-withdraw`: Withdraw funds during emergency
- `set-paused`: Pause/unpause bridge operations
- `set-minimum-amount`: Update minimum transfer amount
- `transfer-ownership`: Transfer contract ownership

## Error Codes

- `ERR_UNAUTHORIZED (u1)`: Unauthorized operation
- `ERR_INVALID_AMOUNT (u2)`: Invalid transfer amount
- `ERR_INSUFFICIENT_BALANCE (u3)`: Insufficient balance
- `ERR_PAUSED (u4)`: Bridge operations paused
- `ERR_INVALID_OPERATION (u5)`: Invalid bridge operation
- `ERR_INVALID_TX (u6)`: Invalid transaction
- `ERR_ALREADY_CLAIMED (u7)`: Bridge already claimed
- `ERR_CLAIM_EXPIRED (u8)`: Claim period expired
- `ERR_INVALID_RECIPIENT (u9)`: Invalid recipient address
- `ERR_INVALID_TX_ID (u10)`: Invalid transaction ID

## Analytics

- Daily volume tracking
- User-specific statistics
- Volume change metrics
- Real-time bridge status monitoring

## Security

- Minimum deposit requirement
- Multi-step verification process
- Owner-only administrative functions
- Emergency pause mechanism
- Transaction verification
- Claim timeout period
- Batch processing limits

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
