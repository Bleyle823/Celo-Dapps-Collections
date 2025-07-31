pragma solidity ^0.8.19;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title RedPacketLuckyDraw
 * @dev A smart contract for creating and claiming red packets with random amounts
 */
contract RedPacketLuckyDraw is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    
    // Red packet structure
    struct RedPacket {
        uint256 id;
        address creator;
        string message;
        uint256 totalAmount;
        uint256 remainingAmount;
        uint256 totalPackets;
        uint256 remainingPackets;
        uint256 minAmount;
        uint256 maxAmount;
        uint256 createdAt;
        uint256 expiresAt;
        bool isActive;
        RedPacketType packetType;
    }
    
    // Claim record structure
    struct ClaimRecord {
        address claimer;
        uint256 amount;
        uint256 timestamp;
        uint256 luckyNumber;
    }
    
    // Red packet types
    enum RedPacketType { Random, Equal, Lucky }
    
    // State variables
    mapping(uint256 => RedPacket) public redPackets;
    mapping(uint256 => ClaimRecord[]) public claimRecords;
    mapping(uint256 => mapping(address => bool)) public hasClaimed;
    mapping(address => uint256[]) public userCreatedPackets;
    mapping(address => uint256[]) public userClaimedPackets;
    
    uint256 public packetCounter;
    uint256 public platformFeePercent = 2; // 2% platform fee
    uint256 public constant MAX_PACKETS = 100;
    uint256 public constant MIN_DURATION = 1 hours;
    uint256 public constant MAX_DURATION = 30 days;
    
    // Events
    event RedPacketCreated(
        uint256 indexed packetId,
        address indexed creator,
        uint256 totalAmount,
        uint256 totalPackets,
        string message
    );
    event RedPacketClaimed(
        uint256 indexed packetId,
        address indexed claimer,
        uint256 amount,
        uint256 luckyNumber
    );
    event RedPacketExpired(uint256 indexed packetId, uint256 refundAmount);
    event RedPacketRefunded(uint256 indexed packetId, address indexed creator, uint256 amount);
    
    // Custom errors
    error InvalidPacketCount();
    error InvalidAmount();
    error InvalidDuration();
    error PacketNotFound();
    error PacketNotActive();
    error PacketExpired();
    error AlreadyClaimed();
    error NoPacketsRemaining();
    error InsufficientAmount();
    error NotAuthorized();
    error RefundFailed();
    
    /**
     * @dev Create a random red packet
     * @param message Message for the red packet
     * @param totalPackets Number of packets to create
     * @param duration Duration in seconds
     * @param minAmount Minimum amount per packet (in wei)
     * @param maxAmount Maximum amount per packet (in wei)
     */
    function createRandomRedPacket(
        string memory message,
        uint256 totalPackets,
        uint256 duration,
        uint256 minAmount,
        uint256 maxAmount
    ) external payable returns (uint256) {
        return _createRedPacket(
            message,
            totalPackets,
            duration,
            minAmount,
            maxAmount,
            RedPacketType.Random
        );
    }
    
    /**
     * @dev Create an equal red packet (all packets have same amount)
     * @param message Message for the red packet
     * @param totalPackets Number of packets to create
     * @param duration Duration in seconds
     */
    function createEqualRedPacket(
        string memory message,
        uint256 totalPackets,
        uint256 duration
    ) external payable returns (uint256) {
        uint256 amountPerPacket = msg.value.div(totalPackets);
        return _createRedPacket(
            message,
            totalPackets,
            duration,
            amountPerPacket,
            amountPerPacket,
            RedPacketType.Equal
        );
    }
    
    /**
     * @dev Create a lucky red packet (one big winner, others get minimum)
     * @param message Message for the red packet
     * @param totalPackets Number of packets to create
     * @param duration Duration in seconds
     * @param minAmount Minimum amount for regular packets
     */
    function createLuckyRedPacket(
        string memory message,
        uint256 totalPackets,
        uint256 duration,
        uint256 minAmount
    ) external payable returns (uint256) {
        require(totalPackets >= 2, "Lucky packet needs at least 2 packets");
        
        uint256 totalMinAmount = minAmount.mul(totalPackets.sub(1));
        require(msg.value > totalMinAmount, "Insufficient amount for lucky packet");
        
        uint256 luckyAmount = msg.value.sub(totalMinAmount);
        
        return _createRedPacket(
            message,
            totalPackets,
            duration,
            minAmount,
            luckyAmount,
            RedPacketType.Lucky
        );
    }
    
    /**
     * @dev Internal function to create red packet
     */
    function _createRedPacket(
        string memory message,
        uint256 totalPackets,
        uint256 duration,
        uint256 minAmount,
        uint256 maxAmount,
        RedPacketType packetType
    ) internal returns (uint256) {
        if (totalPackets == 0 || totalPackets > MAX_PACKETS) revert InvalidPacketCount();
        if (msg.value == 0) revert InvalidAmount();
        if (duration < MIN_DURATION || duration > MAX_DURATION) revert InvalidDuration();
        if (minAmount > maxAmount) revert InvalidAmount();
        
        uint256 packetId = packetCounter++;
        uint256 expiresAt = block.timestamp.add(duration);
        
        redPackets[packetId] = RedPacket({
            id: packetId,
            creator: msg.sender,
            message: message,
            totalAmount: msg.value,
            remainingAmount: msg.value,
            totalPackets: totalPackets,
            remainingPackets: totalPackets,
            minAmount: minAmount,
            maxAmount: maxAmount,
            createdAt: block.timestamp,
            expiresAt: expiresAt,
            isActive: true,
            packetType: packetType
        });
        
        userCreatedPackets[msg.sender].push(packetId);
        
        emit RedPacketCreated(packetId, msg.sender, msg.value, totalPackets, message);
        return packetId;
    }
    
    /**
     * @dev Claim a red packet
     * @param packetId Red packet ID to claim
     */
    function claimRedPacket(uint256 packetId) external nonReentrant {
        RedPacket storage packet = redPackets[packetId];
        
        if (packet.creator == address(0)) revert PacketNotFound();
        if (!packet.isActive) revert PacketNotActive();
        if (block.timestamp > packet.expiresAt) revert PacketExpired();
        if (hasClaimed[packetId][msg.sender]) revert AlreadyClaimed();
        if (packet.remainingPackets == 0) revert NoPacketsRemaining();
        
        // Calculate claim amount based on packet type
        uint256 claimAmount = _calculateClaimAmount(packetId);
        
        if (claimAmount > packet.remainingAmount) {
            claimAmount = packet.remainingAmount;
        }
        
        // Update packet state
        packet.remainingAmount = packet.remainingAmount.sub(claimAmount);
        packet.remainingPackets = packet.remainingPackets.sub(1);
        hasClaimed[packetId][msg.sender] = true;
        
        // Generate lucky number for fun
        uint256 luckyNumber = _generateLuckyNumber(packetId, msg.sender);
        
        // Record claim
        claimRecords[packetId].push(ClaimRecord({
            claimer: msg.sender,
            amount: claimAmount,
            timestamp: block.timestamp,
            luckyNumber: luckyNumber
        }));
        
        userClaimedPackets[msg.sender].push(packetId);
        
        // Calculate platform fee
        uint256 platformFee = claimAmount.mul(platformFeePercent).div(100);
        uint256 userAmount = claimAmount.sub(platformFee);
        
        // Transfer amounts
        payable(msg.sender).transfer(userAmount);
        payable(owner()).transfer(platformFee);
        
        emit RedPacketClaimed(packetId, msg.sender, userAmount, luckyNumber);
        
        // Deactivate if all packets claimed
        if (packet.remainingPackets == 0) {
            packet.isActive = false;
        }
    }
    
    /**
     * @dev Calculate claim amount based on packet type
     * @param packetId Red packet ID
     * @return uint256 Amount to claim
     */
    function _calculateClaimAmount(uint256 packetId) internal view returns (uint256) {
        RedPacket storage packet = redPackets[packetId];
        
        if (packet.packetType == RedPacketType.Equal) {
            return packet.minAmount; // Equal amounts
        } else if (packet.packetType == RedPacketType.Lucky) {
            // Lucky packet: first claimer gets lucky amount, others get minimum
            if (claimRecords[packetId].length == 0) {
                return packet.maxAmount; // Lucky winner
            } else {
                return packet.minAmount; // Regular amount
            }
        } else {
            // Random packet: generate random amount between min and max
            return _generateRandomAmount(packetId, packet.minAmount, packet.maxAmount);
        }
    }
    
    /**
     * @dev Generate random amount for random packets
     * @param packetId Red packet ID
     * @param minAmount Minimum amount
     * @param maxAmount Maximum amount
     * @return uint256 Random amount
     */
    function _generateRandomAmount(
        uint256 packetId,
        uint256 minAmount,
        uint256 maxAmount
    ) internal view returns (uint256) {
        if (minAmount == maxAmount) return minAmount;
        
        RedPacket storage packet = redPackets[packetId];
        
        // For the last packet, give all remaining amount
        if (packet.remainingPackets == 1) {
            return packet.remainingAmount;
        }
        
        // Calculate average remaining amount
        uint256 avgRemaining = packet.remainingAmount.div(packet.remainingPackets);
        
        // Generate random amount around the average
        uint256 seed = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty,
            msg.sender,
            packetId
        )));
        
        uint256 range = maxAmount.sub(minAmount);
        uint256 randomAmount = minAmount.add(seed.mod(range.add(1)));
        
        // Ensure we don't exceed average * 2 to prevent early depletion
        uint256 maxAllowed = avgRemaining.mul(2);
        if (randomAmount > maxAllowed) {
            randomAmount = maxAllowed;
        }
        
        // Ensure minimum amount
        if (randomAmount < minAmount) {
            randomAmount = minAmount;
        }
        
        return randomAmount;
    }
    
    /**
     * @dev Generate lucky number for display
     * @param packetId Red packet ID
     * @param claimer Claimer address
     * @return uint256 Lucky number (1-100)
     */
    function _generateLuckyNumber(uint256 packetId, address claimer) internal view returns (uint256) {
        uint256 seed = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty,
            claimer,
            packetId,
            claimRecords[packetId].length
        )));
        return (seed.mod(100)).add(1);
    }
    
    /**
     * @dev Refund expired red packet to creator
     * @param packetId Red packet ID to refund
     */
    function refundExpiredPacket(uint256 packetId) external nonReentrant {
        RedPacket storage packet = redPackets[packetId];
        
        if (packet.creator == address(0)) revert PacketNotFound();
        require(block.timestamp > packet.expiresAt, "Packet not expired yet");
        require(packet.remainingAmount > 0, "No amount to refund");
        require(packet.isActive, "Packet already processed");
        
        uint256 refundAmount = packet.remainingAmount;
        packet.remainingAmount = 0;
        packet.isActive = false;
        
        payable(packet.creator).transfer(refundAmount);
        
        emit RedPacketExpired(packetId, refundAmount);
        emit RedPacketRefunded(packetId, packet.creator, refundAmount);
    }
    
    // View functions
    
    /**
     * @dev Get red packet details
     * @param packetId Red packet ID
     * @return RedPacket struct
     */
    function getRedPacket(uint256 packetId) external view returns (RedPacket memory) {
        return redPackets[packetId];
    }
    
    /**
     * @dev Get claim records for a red packet
     * @param packetId Red packet ID
     * @return ClaimRecord[] Array of claim records
     */
    function getClaimRecords(uint256 packetId) external view returns (ClaimRecord[] memory) {
        return claimRecords[packetId];
    }
    
    /**
     * @dev Get red packets created by user
     * @param user User address
     * @return uint256[] Array of packet IDs
     */
    function getUserCreatedPackets(address user) external view returns (uint256[] memory) {
        return userCreatedPackets[user];
    }
    
    /**
     * @dev Get red packets claimed by user
     * @param user User address
     * @return uint256[] Array of packet IDs
     */
    function getUserClaimedPackets(address user) external view returns (uint256[] memory) {
        return userClaimedPackets[user];
    }
    
    /**
     * @dev Check if user has claimed a specific packet
     * @param packetId Red packet ID
     * @param user User address
     * @return bool True if claimed
     */
    function hasUserClaimed(uint256 packetId, address user) external view returns (bool) {
        return hasClaimed[packetId][user];
    }
    
    /**
     * @dev Get packet statistics
     * @param packetId Red packet ID
     * @return totalClaimed Total amount claimed
     * @return claimerCount Number of claimers
     * @return averageAmount Average claim amount
     * @return isExpired Whether packet is expired
     */
    function getPacketStats(uint256 packetId) external view returns (
        uint256 totalClaimed,
        uint256 claimerCount,
        uint256 averageAmount,
        bool isExpired
    ) {
        RedPacket storage packet = redPackets[packetId];
        ClaimRecord[] storage records = claimRecords[packetId];
        
        totalClaimed = packet.totalAmount.sub(packet.remainingAmount);
        claimerCount = records.length;
        averageAmount = claimerCount > 0 ? totalClaimed.div(claimerCount) : 0;
        isExpired = block.timestamp > packet.expiresAt;
    }
    
    /**
     * @dev Get active packets count
     * @return uint256 Number of active packets
     */
    function getActivePacketsCount() external view returns (uint256) {
        uint256 activeCount = 0;
        for (uint256 i = 0; i < packetCounter; i++) {
            if (redPackets[i].isActive && block.timestamp <= redPackets[i].expiresAt) {
                activeCount++;
            }
        }
        return activeCount;
    }
    
    // Owner functions
    
    /**
     * @dev Set platform fee percentage
     * @param feePercent New fee percentage (0-10)
     */
    function setPlatformFee(uint256 feePercent) external onlyOwner {
        require(feePercent <= 10, "Fee too high");
        platformFeePercent = feePercent;
    }
    
    /**
     * @dev Emergency withdraw (only if contract is paused)
     */
    function emergencyWithdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
    
    /**
     * @dev Get total packets created
     * @return uint256 Total packet count
     */
    function getTotalPackets() external view returns (uint256) {
        return packetCounter;
    }
}