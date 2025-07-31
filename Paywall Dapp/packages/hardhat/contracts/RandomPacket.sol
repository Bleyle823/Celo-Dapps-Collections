// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface VRFCoordinatorV2Interface {
    function requestRandomWords(
        bytes32 keyHash,
        uint64 subId,
        uint16 minimumRequestConfirmations,
        uint32 callbackGasLimit,
        uint32 numWords
    ) external returns (uint256 requestId);
}

interface VRFConsumerBaseV2Interface {
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external;
}

/**
 * @title RandomPacket
 * @dev A smart contract for creating random packets with various reward types
 * Supports multiple randomness sources and packet types
 */
contract RandomPacket {
    
    // Events
    event PacketCreated(uint256 indexed packetId, address indexed creator, uint256 totalValue);
    event PacketOpened(uint256 indexed packetId, address indexed opener, uint256 reward, RewardType rewardType);
    event RandomnessRequested(uint256 indexed requestId, uint256 indexed packetId);
    event RandomnessFulfilled(uint256 indexed requestId, uint256 randomValue);
    
    // Enums
    enum PacketStatus { Active, Opened, Expired, Cancelled }
    enum RewardType { ETH, Token, NFT, Empty }
    enum RandomnessSource { BlockHash, VRF, CommitReveal }
    
    // Structs
    struct Packet {
        address creator;
        uint256 totalValue;
        uint256 createdAt;
        uint256 expiresAt;
        PacketStatus status;
        RewardType[] rewardTypes;
        uint256[] rewardAmounts;
        address[] tokenAddresses;
        uint256[] nftIds;
        RandomnessSource randomnessSource;
        bool requiresVRF;
        uint256 vrfRequestId;
    }
    
    struct CommitRevealData {
        bytes32 commitment;
        uint256 revealDeadline;
        bool revealed;
        uint256 nonce;
    }
    
    // State variables
    mapping(uint256 => Packet) public packets;
    mapping(uint256 => CommitRevealData) public commitRevealData;
    mapping(uint256 => uint256) public vrfRequestToPacket;
    mapping(address => uint256[]) public userPackets;
    
    uint256 public nextPacketId = 1;
    uint256 public defaultExpiryTime = 7 days;
    uint256 public commitRevealWindow = 1 hours;
    
    // VRF variables (Chainlink VRF V2)
    VRFCoordinatorV2Interface public vrfCoordinator;
    bytes32 public keyHash;
    uint64 public subscriptionId;
    uint16 public requestConfirmations = 3;
    uint32 public callbackGasLimit = 100000;
    
    // Access control
    address public owner;
    mapping(address => bool) public authorizedCreators;
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    modifier onlyAuthorized() {
        require(authorizedCreators[msg.sender] || msg.sender == owner, "Not authorized");
        _;
    }
    
    constructor(
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint64 _subscriptionId
    ) {
        owner = msg.sender;
        authorizedCreators[msg.sender] = true;
        vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        keyHash = _keyHash;
        subscriptionId = _subscriptionId;
    }
    
    /**
     * @dev Create a simple ETH packet with block hash randomness
     */
    function createETHPacket(
        uint256 _numRewards,
        uint256[] memory _rewardAmounts
    ) external payable returns (uint256) {
        require(_numRewards > 0 && _numRewards <= 10, "Invalid reward count");
        require(_rewardAmounts.length == _numRewards, "Mismatched arrays");
        
        uint256 totalValue = 0;
        for (uint i = 0; i < _rewardAmounts.length; i++) {
            totalValue += _rewardAmounts[i];
        }
        require(msg.value >= totalValue, "Insufficient ETH sent");
        
        RewardType[] memory rewardTypes = new RewardType[](_numRewards);
        for (uint i = 0; i < _numRewards; i++) {
            rewardTypes[i] = RewardType.ETH;
        }
        
        uint256 packetId = _createPacket(
            totalValue,
            rewardTypes,
            _rewardAmounts,
            new address[](_numRewards),
            new uint256[](_numRewards),
            RandomnessSource.BlockHash
        );
        
        return packetId;
    }
    
    /**
     * @dev Create a token packet with VRF randomness
     */
    function createTokenPacket(
        address _tokenAddress,
        uint256[] memory _rewardAmounts,
        bool _useVRF
    ) external returns (uint256) {
        require(_rewardAmounts.length > 0 && _rewardAmounts.length <= 10, "Invalid reward count");
        
        uint256 totalValue = 0;
        for (uint i = 0; i < _rewardAmounts.length; i++) {
            totalValue += _rewardAmounts[i];
        }
        
        IERC20 token = IERC20(_tokenAddress);
        require(token.transferFrom(msg.sender, address(this), totalValue), "Token transfer failed");
        
        RewardType[] memory rewardTypes = new RewardType[](_rewardAmounts.length);
        address[] memory tokenAddresses = new address[](_rewardAmounts.length);
        
        for (uint i = 0; i < _rewardAmounts.length; i++) {
            rewardTypes[i] = RewardType.Token;
            tokenAddresses[i] = _tokenAddress;
        }
        
        uint256 packetId = _createPacket(
            totalValue,
            rewardTypes,
            _rewardAmounts,
            tokenAddresses,
            new uint256[](_rewardAmounts.length),
            _useVRF ? RandomnessSource.VRF : RandomnessSource.BlockHash
        );
        
        return packetId;
    }
    
    /**
     * @dev Create a mixed packet with commit-reveal randomness
     */
    function createMixedPacket(
        RewardType[] memory _rewardTypes,
        uint256[] memory _rewardAmounts,
        address[] memory _tokenAddresses,
        uint256[] memory _nftIds
    ) external payable returns (uint256) {
        require(_rewardTypes.length > 0 && _rewardTypes.length <= 10, "Invalid reward count");
        require(_rewardTypes.length == _rewardAmounts.length, "Mismatched arrays");
        
        uint256 ethValue = 0;
        for (uint i = 0; i < _rewardTypes.length; i++) {
            if (_rewardTypes[i] == RewardType.ETH) {
                ethValue += _rewardAmounts[i];
            } else if (_rewardTypes[i] == RewardType.Token) {
                require(_tokenAddresses[i] != address(0), "Invalid token address");
                IERC20(_tokenAddresses[i]).transferFrom(msg.sender, address(this), _rewardAmounts[i]);
            }
        }
        
        require(msg.value >= ethValue, "Insufficient ETH sent");
        
        uint256 packetId = _createPacket(
            msg.value,
            _rewardTypes,
            _rewardAmounts,
            _tokenAddresses,
            _nftIds,
            RandomnessSource.CommitReveal
        );
        
        return packetId;
    }
    
    /**
     * @dev Internal function to create a packet
     */
    function _createPacket(
        uint256 _totalValue,
        RewardType[] memory _rewardTypes,
        uint256[] memory _rewardAmounts,
        address[] memory _tokenAddresses,
        uint256[] memory _nftIds,
        RandomnessSource _randomnessSource
    ) internal returns (uint256) {
        uint256 packetId = nextPacketId++;
        
        Packet storage packet = packets[packetId];
        packet.creator = msg.sender;
        packet.totalValue = _totalValue;
        packet.createdAt = block.timestamp;
        packet.expiresAt = block.timestamp + defaultExpiryTime;
        packet.status = PacketStatus.Active;
        packet.rewardTypes = _rewardTypes;
        packet.rewardAmounts = _rewardAmounts;
        packet.tokenAddresses = _tokenAddresses;
        packet.nftIds = _nftIds;
        packet.randomnessSource = _randomnessSource;
        packet.requiresVRF = (_randomnessSource == RandomnessSource.VRF);
        
        userPackets[msg.sender].push(packetId);
        
        emit PacketCreated(packetId, msg.sender, _totalValue);
        
        return packetId;
    }
    
    /**
     * @dev Open a packet using block hash randomness
     */
    function openPacket(uint256 _packetId) external {
        Packet storage packet = packets[_packetId];
        require(packet.status == PacketStatus.Active, "Packet not active");
        require(block.timestamp <= packet.expiresAt, "Packet expired");
        require(!packet.requiresVRF, "Use VRF opening method");
        require(packet.randomnessSource != RandomnessSource.CommitReveal, "Use commit-reveal method");
        
        uint256 randomValue = _generateBlockHashRandom(_packetId);
        _distributeReward(_packetId, randomValue, msg.sender);
    }
    
    /**
     * @dev Open packet with VRF randomness
     */
    function openPacketWithVRF(uint256 _packetId) external {
        Packet storage packet = packets[_packetId];
        require(packet.status == PacketStatus.Active, "Packet not active");
        require(block.timestamp <= packet.expiresAt, "Packet expired");
        require(packet.requiresVRF, "Use regular opening method");
        require(packet.vrfRequestId == 0, "VRF already requested");
        
        uint256 requestId = vrfCoordinator.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            1
        );
        
        packet.vrfRequestId = requestId;
        vrfRequestToPacket[requestId] = _packetId;
        
        emit RandomnessRequested(requestId, _packetId);
    }
    
    /**
     * @dev Chainlink VRF callback
     */
    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) external {
        require(msg.sender == address(vrfCoordinator), "Only VRF coordinator");
        
        uint256 packetId = vrfRequestToPacket[_requestId];
        require(packetId != 0, "Invalid request ID");
        
        uint256 randomValue = _randomWords[0];
        emit RandomnessFulfilled(_requestId, randomValue);
        
        Packet storage packet = packets[packetId];
        // Find who initiated the VRF request (simplified - in production, store this)
        address opener = packet.creator; // This should be stored when VRF is requested
        
        _distributeReward(packetId, randomValue, opener);
    }
    
    /**
     * @dev Commit phase for commit-reveal randomness
     */
    function commitForPacket(uint256 _packetId, bytes32 _commitment) external {
        Packet storage packet = packets[_packetId];
        require(packet.status == PacketStatus.Active, "Packet not active");
        require(packet.randomnessSource == RandomnessSource.CommitReveal, "Not commit-reveal packet");
        
        commitRevealData[_packetId] = CommitRevealData({
            commitment: _commitment,
            revealDeadline: block.timestamp + commitRevealWindow,
            revealed: false,
            nonce: 0
        });
    }
    
    /**
     * @dev Reveal phase for commit-reveal randomness
     */
    function revealAndOpen(uint256 _packetId, uint256 _nonce, uint256 _value) external {
        Packet storage packet = packets[_packetId];
        CommitRevealData storage commitData = commitRevealData[_packetId];
        
        require(packet.status == PacketStatus.Active, "Packet not active");
        require(block.timestamp <= commitData.revealDeadline, "Reveal deadline passed");
        require(!commitData.revealed, "Already revealed");
        require(
            keccak256(abi.encodePacked(_value, _nonce)) == commitData.commitment,
            "Invalid reveal"
        );
        
        commitData.revealed = true;
        commitData.nonce = _nonce;
        
        uint256 randomValue = uint256(keccak256(abi.encodePacked(_value, block.timestamp, block.difficulty)));
        _distributeReward(_packetId, randomValue, msg.sender);
    }
    
    /**
     * @dev Generate pseudo-random number using block hash
     */
    function _generateBlockHashRandom(uint256 _packetId) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty,
            msg.sender,
            _packetId,
            blockhash(block.number - 1)
        )));
    }
    
    /**
     * @dev Distribute reward based on random value
     */
    function _distributeReward(uint256 _packetId, uint256 _randomValue, address _opener) internal {
        Packet storage packet = packets[_packetId];
        packet.status = PacketStatus.Opened;
        
        if (packet.rewardTypes.length == 0) {
            emit PacketOpened(_packetId, _opener, 0, RewardType.Empty);
            return;
        }
        
        uint256 rewardIndex = _randomValue % packet.rewardTypes.length;
        RewardType rewardType = packet.rewardTypes[rewardIndex];
        uint256 rewardAmount = packet.rewardAmounts[rewardIndex];
        
        if (rewardType == RewardType.ETH) {
            payable(_opener).transfer(rewardAmount);
        } else if (rewardType == RewardType.Token) {
            IERC20(packet.tokenAddresses[rewardIndex]).transfer(_opener, rewardAmount);
        }
        // NFT transfers would be implemented here
        
        emit PacketOpened(_packetId, _opener, rewardAmount, rewardType);
    }
    
    /**
     * @dev Cancel an expired packet and refund creator
     */
    function cancelExpiredPacket(uint256 _packetId) external {
        Packet storage packet = packets[_packetId];
        require(packet.status == PacketStatus.Active, "Packet not active");
        require(block.timestamp > packet.expiresAt, "Packet not expired");
        require(msg.sender == packet.creator || msg.sender == owner, "Not authorized");
        
        packet.status = PacketStatus.Cancelled;
        
        // Refund ETH
        if (packet.totalValue > 0) {
            payable(packet.creator).transfer(packet.totalValue);
        }
        
        // Refund tokens
        for (uint i = 0; i < packet.rewardTypes.length; i++) {
            if (packet.rewardTypes[i] == RewardType.Token) {
                IERC20(packet.tokenAddresses[i]).transfer(packet.creator, packet.rewardAmounts[i]);
            }
        }
    }
    
    /**
     * @dev Get packet details
     */
    function getPacket(uint256 _packetId) external view returns (
        address creator,
        uint256 totalValue,
        uint256 createdAt,
        uint256 expiresAt,
        PacketStatus status,
        uint256 rewardCount
    ) {
        Packet storage packet = packets[_packetId];
        return (
            packet.creator,
            packet.totalValue,
            packet.createdAt,
            packet.expiresAt,
            packet.status,
            packet.rewardTypes.length
        );
    }
    
    /**
     * @dev Get user's packets
     */
    function getUserPackets(address _user) external view returns (uint256[] memory) {
        return userPackets[_user];
    }
    
    /**
     * @dev Admin functions
     */
    function setAuthorizedCreator(address _creator, bool _authorized) external onlyOwner {
        authorizedCreators[_creator] = _authorized;
    }
    
    function setDefaultExpiryTime(uint256 _expiryTime) external onlyOwner {
        defaultExpiryTime = _expiryTime;
    }
    
    function setVRFParameters(
        bytes32 _keyHash,
        uint64 _subscriptionId,
        uint16 _requestConfirmations,
        uint32 _callbackGasLimit
    ) external onlyOwner {
        keyHash = _keyHash;
        subscriptionId = _subscriptionId;
        requestConfirmations = _requestConfirmations;
        callbackGasLimit = _callbackGasLimit;
    }
    
    /**
     * @dev Emergency withdrawal function
     */
    function emergencyWithdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
    
    // Receive function to accept ETH
    receive() external payable {}
}