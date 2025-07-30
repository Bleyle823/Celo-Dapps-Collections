// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title PiggyBank
 * @dev A time-locked savings contract where users can deposit ETH and withdraw only after lock period
 */
contract PiggyBank {
    struct Savings {
        uint256 amount;
        uint256 unlockTime;
        bool exists;
    }

    mapping(address => Savings) public piggyBanks;
    
    event Deposit(address indexed user, uint256 amount, uint256 unlockTime);
    event Withdrawal(address indexed user, uint256 amount);
    event PiggyBankSmashed(address indexed user, uint256 amount);

    error NoSavings();
    error StillLocked(uint256 timeRemaining);
    error NoDeposit();
    error TransferFailed();

    /**
     * @dev Create a piggy bank with a lock duration in seconds
     * @param _lockDurationInSeconds Duration to lock the funds (e.g., 86400 for 1 day)
     */
    function createPiggyBank(uint256 _lockDurationInSeconds) external payable {
        require(msg.value > 0, "Must deposit some ETH");
        require(_lockDurationInSeconds > 0, "Lock duration must be positive");

        uint256 unlockTime = block.timestamp + _lockDurationInSeconds;
        
        if (piggyBanks[msg.sender].exists) {
            // Add to existing piggy bank and extend lock time if new time is longer
            piggyBanks[msg.sender].amount += msg.value;
            if (unlockTime > piggyBanks[msg.sender].unlockTime) {
                piggyBanks[msg.sender].unlockTime = unlockTime;
            }
        } else {
            // Create new piggy bank
            piggyBanks[msg.sender] = Savings({
                amount: msg.value,
                unlockTime: unlockTime,
                exists: true
            });
        }

        emit Deposit(msg.sender, msg.value, piggyBanks[msg.sender].unlockTime);
    }

    /**
     * @dev Add more funds to existing piggy bank
     */
    function addFunds() external payable {
        if (!piggyBanks[msg.sender].exists) revert NoSavings();
        require(msg.value > 0, "Must deposit some ETH");

        piggyBanks[msg.sender].amount += msg.value;
        
        emit Deposit(msg.sender, msg.value, piggyBanks[msg.sender].unlockTime);
    }

    /**
     * @dev Withdraw funds after lock period expires
     */
    function withdraw() external {
        Savings storage savings = piggyBanks[msg.sender];
        
        if (!savings.exists) revert NoSavings();
        if (block.timestamp < savings.unlockTime) {
            revert StillLocked(savings.unlockTime - block.timestamp);
        }

        uint256 amount = savings.amount;
        
        // Clear the piggy bank before transfer (CEI pattern)
        delete piggyBanks[msg.sender];

        // Transfer the funds
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) revert TransferFailed();

        emit Withdrawal(msg.sender, amount);
    }

    /**
     * @dev Emergency withdrawal with penalty (loses 10% of funds)
     * Use this only in real emergencies!
     */
    function emergencyWithdraw() external {
        Savings storage savings = piggyBanks[msg.sender];
        
        if (!savings.exists) revert NoSavings();

        uint256 penalty = savings.amount / 10; // 10% penalty
        uint256 withdrawAmount = savings.amount - penalty;
        uint256 totalAmount = savings.amount;

        // Clear the piggy bank before transfer
        delete piggyBanks[msg.sender];

        // Transfer funds minus penalty
        (bool success, ) = payable(msg.sender).call{value: withdrawAmount}("");
        if (!success) revert TransferFailed();

        emit PiggyBankSmashed(msg.sender, totalAmount);
    }

    /**
     * @dev Check how much time is left until withdrawal
     * @return timeLeft seconds remaining, 0 if unlocked
     */
    function getTimeLeft(address user) external view returns (uint256 timeLeft) {
        if (!piggyBanks[user].exists) return 0;
        
        uint256 unlockTime = piggyBanks[user].unlockTime;
        if (block.timestamp >= unlockTime) {
            return 0;
        }
        return unlockTime - block.timestamp;
    }

    /**
     * @dev Get piggy bank details for a user
     */
    function getPiggyBank(address user) external view returns (
        uint256 amount,
        uint256 unlockTime,
        bool isUnlocked,
        bool exists
    ) {
        Savings memory savings = piggyBanks[user];
        return (
            savings.amount,
            savings.unlockTime,
            block.timestamp >= savings.unlockTime,
            savings.exists
        );
    }

    /**
     * @dev Get current block timestamp (useful for frontend)
     */
    function getCurrentTime() external view returns (uint256) {
        return block.timestamp;
    }

    /**
     * @dev Helper function to calculate lock time for common durations
     */
    function getLockDuration(string memory duration) external pure returns (uint256) {
        bytes32 durationHash = keccak256(abi.encodePacked(duration));
        
        if (durationHash == keccak256(abi.encodePacked("1hour"))) return 3600;
        if (durationHash == keccak256(abi.encodePacked("1day"))) return 86400;
        if (durationHash == keccak256(abi.encodePacked("1week"))) return 604800;
        if (durationHash == keccak256(abi.encodePacked("1month"))) return 2592000; // 30 days
        if (durationHash == keccak256(abi.encodePacked("1year"))) return 31536000; // 365 days
        
        return 0; // Invalid duration
    }

    // Prevent accidental ETH sends to contract
    receive() external payable {
        revert("Use createPiggyBank() function to deposit");
    }
}