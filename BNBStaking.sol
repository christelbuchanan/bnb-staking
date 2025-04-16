// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title BNBStaking
 * @dev A staking contract for BNB Chain that allows users to stake BNB and earn rewards
 */
contract BNBStaking {
    // Staking information for each user
    struct StakeInfo {
        uint256 amount;         // Amount of BNB staked
        uint256 since;          // Timestamp when the stake was created
        uint256 claimedRewards; // Total rewards claimed so far
    }
    
    // Mapping from user address to their staking information
    mapping(address => StakeInfo) public stakes;
    
    // Total staked amount across all users
    uint256 public totalStaked;
    
    // Annual percentage yield (APY) in basis points (1% = 100 basis points)
    uint256 public rewardRate = 1000; // 10% APY by default
    
    // Minimum staking period in seconds (7 days by default)
    uint256 public minimumStakingPeriod = 7 days;
    
    // Contract owner
    address public owner;
    
    // Events
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardRateUpdated(uint256 newRate);
    event MinimumStakingPeriodUpdated(uint256 newPeriod);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Stake BNB tokens
     */
    function stake() external payable {
        require(msg.value > 0, "Cannot stake 0 BNB");
        
        // Calculate any pending rewards before updating stake
        uint256 pendingReward = calculateReward(msg.sender);
        
        // Update stake information
        if (stakes[msg.sender].amount > 0) {
            // If user already has a stake, add to it
            stakes[msg.sender].amount += msg.value;
        } else {
            // Create new stake
            stakes[msg.sender] = StakeInfo({
                amount: msg.value,
                since: block.timestamp,
                claimedRewards: 0
            });
        }
        
        // Update total staked amount
        totalStaked += msg.value;
        
        emit Staked(msg.sender, msg.value);
        
        // If there were pending rewards, pay them out
        if (pendingReward > 0) {
            payReward(pendingReward);
        }
    }
    
    /**
     * @dev Withdraw staked BNB tokens
     * @param amount Amount of BNB to withdraw
     */
    function withdraw(uint256 amount) external {
        StakeInfo storage userStake = stakes[msg.sender];
        require(userStake.amount >= amount, "Insufficient staked amount");
        require(block.timestamp >= userStake.since + minimumStakingPeriod, "Minimum staking period not reached");
        
        // Calculate rewards before withdrawal
        uint256 reward = calculateReward(msg.sender);
        
        // Update stake information
        userStake.amount -= amount;
        totalStaked -= amount;
        
        // If stake is now 0, reset the since timestamp
        if (userStake.amount == 0) {
            userStake.since = 0;
        }
        
        emit Withdrawn(msg.sender, amount);
        
        // Transfer BNB back to user
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");
        
        // Pay out any pending rewards
        if (reward > 0) {
            payReward(reward);
        }
    }
    
    /**
     * @dev Claim accumulated rewards without withdrawing stake
     */
    function claimRewards() external {
        uint256 reward = calculateReward(msg.sender);
        require(reward > 0, "No rewards to claim");
        
        // Reset the reward calculation by updating the since timestamp
        stakes[msg.sender].since = block.timestamp;
        stakes[msg.sender].claimedRewards += reward;
        
        payReward(reward);
    }
    
    /**
     * @dev Calculate pending rewards for a user
     * @param user Address of the user
     * @return Pending reward amount
     */
    function calculateReward(address user) public view returns (uint256) {
        StakeInfo storage userStake = stakes[user];
        
        if (userStake.amount == 0 || userStake.since == 0) {
            return 0;
        }
        
        // Calculate staking duration in seconds
        uint256 stakingDuration = block.timestamp - userStake.since;
        
        // Calculate reward based on staking amount, duration, and reward rate
        // rewardRate is in basis points (1/100 of a percent)
        // 10000 basis points = 100%
        uint256 reward = (userStake.amount * stakingDuration * rewardRate) / (365 days * 10000);
        
        return reward;
    }
    
    /**
     * @dev Internal function to pay out rewards
     * @param amount Reward amount to pay
     */
    function payReward(uint256 amount) internal {
        emit RewardPaid(msg.sender, amount);
        
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Reward transfer failed");
    }
    
    /**
     * @dev Get staking information for a user
     * @param user Address of the user
     * @return Staked amount, staking timestamp, and claimed rewards
     */
    function getStakeInfo(address user) external view returns (uint256, uint256, uint256) {
        StakeInfo storage userStake = stakes[user];
        return (userStake.amount, userStake.since, userStake.claimedRewards);
    }
    
    /**
     * @dev Update the reward rate (only owner)
     * @param newRate New reward rate in basis points
     */
    function setRewardRate(uint256 newRate) external onlyOwner {
        require(newRate <= 5000, "Rate too high"); // Maximum 50% APY
        rewardRate = newRate;
        emit RewardRateUpdated(newRate);
    }
    
    /**
     * @dev Update the minimum staking period (only owner)
     * @param newPeriod New minimum staking period in seconds
     */
    function setMinimumStakingPeriod(uint256 newPeriod) external onlyOwner {
        require(newPeriod <= 365 days, "Period too long"); // Maximum 1 year
        minimumStakingPeriod = newPeriod;
        emit MinimumStakingPeriodUpdated(newPeriod);
    }
    
    /**
     * @dev Add funds to the contract for reward distribution (only owner)
     */
    function addRewardFunds() external payable onlyOwner {
        require(msg.value > 0, "Must send BNB");
        // Funds are simply added to the contract balance
    }
    
    /**
     * @dev Emergency withdraw function for contract owner
     * @param amount Amount to withdraw
     */
    function emergencyWithdraw(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance - totalStaked, "Cannot withdraw staked funds");
        
        (bool success, ) = payable(owner).call{value: amount}("");
        require(success, "Transfer failed");
    }
    
    /**
     * @dev Transfer ownership of the contract
     * @param newOwner Address of the new owner
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        owner = newOwner;
    }
    
    /**
     * @dev Get contract balance
     * @return Contract balance
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
