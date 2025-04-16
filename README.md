# BNB Chain Staking Contract

This smart contract allows users to stake BNB tokens on the BNB Chain (formerly Binance Smart Chain) and earn rewards based on the staking duration.

## Features

- Stake BNB tokens and earn rewards
- Withdraw staked tokens after the minimum staking period
- Claim rewards without withdrawing stake
- Configurable reward rate and minimum staking period
- Admin functions for contract management

## Contract Functions

### User Functions

- `stake()` - Stake BNB tokens (payable function)
- `withdraw(uint256 amount)` - Withdraw staked BNB tokens
- `claimRewards()` - Claim accumulated rewards without withdrawing stake
- `calculateReward(address user)` - Calculate pending rewards for a user
- `getStakeInfo(address user)` - Get staking information for a user

### Admin Functions

- `setRewardRate(uint256 newRate)` - Update the reward rate (in basis points)
- `setMinimumStakingPeriod(uint256 newPeriod)` - Update the minimum staking period
- `addRewardFunds()` - Add funds to the contract for reward distribution
- `emergencyWithdraw(uint256 amount)` - Emergency withdraw function for contract owner
- `transferOwnership(address newOwner)` - Transfer ownership of the contract
- `getContractBalance()` - Get contract balance

## Reward Calculation

Rewards are calculated based on:
- Staking amount
- Staking duration
- Reward rate (APY in basis points)

The formula used is:
```
reward = (stakedAmount * stakingDuration * rewardRate) / (365 days * 10000)
```

Where:
- `stakedAmount` is the amount of BNB staked
- `stakingDuration` is the time since the stake was created (in seconds)
- `rewardRate` is the annual percentage yield in basis points (1% = 100 basis points)

## Deployment

To deploy this contract on BNB Chain:

1. Use Remix, Truffle, or Hardhat to compile the contract
2. Deploy to BNB Chain Testnet for testing
3. Deploy to BNB Chain Mainnet for production

## Security Considerations

- The contract owner has significant control over the contract parameters
- Ensure sufficient funds are available in the contract to pay rewards
- Consider having the contract audited before deploying with significant value
