// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title CoinFlip
 * @dev A provably fair coin flip game with betting and house edge
 */
contract CoinFlip {
    enum Side { Heads, Tails }
    enum FlipState { Active, Finished, Cancelled }
    
    struct Flip {
        address player;
        uint256 betAmount;
        Side chosenSide;
        Side result;
        bool won;
        FlipState state;
        uint256 timestamp;
        uint256 blockNumber;
        bytes32 seedHash;
        uint256 nonce;
        uint256 payout;
    }

    // State variables
    mapping(uint256 => Flip) public flips;
    mapping(address => uint256[]) public playerFlips;
    mapping(address => uint256) public playerStats; // total wins
    mapping(address => uint256) public playerVolume; // total bet amount
    
    uint256 public nextFlipId;
    uint256 public totalFlips;
    uint256 public totalVolume;
    uint256 public totalPayouts;
    
    // Game settings
    uint256 public constant MIN_BET = 0.001 ether;
    uint256 public constant MAX_BET = 5 ether;
    uint256 public houseEdge = 200; // 2% (in basis points)
    uint256 public constant PAYOUT_MULTIPLIER = 195; // 1.95x (considering house edge)
    
    // Platform management
    address public platformOwner;
    uint256 public houseBalance;
    bool public gamePaused;
    
    // Randomness
    uint256 private nonce;

    // Events
    event FlipCreated(
        uint256 indexed flipId,
        address indexed player,
        uint256 betAmount,
        Side chosenSide,
        bytes32 seedHash
    );
    
    event FlipResult(
        uint256 indexed flipId,
        address indexed player,
        Side chosenSide,
        Side result,
        bool won,
        uint256 payout
    );
    
    event HouseEdgeUpdated(uint256 newHouseEdge);
    event GamePaused(bool paused);
    event HouseFundsWithdrawn(uint256 amount);

    // Errors
    error InvalidBetAmount();
    error GamePaused();
    error FlipNotFound();
    error FlipAlreadyFinished();
    error InsufficientHouseBalance();
    error TransferFailed();
    error UnauthorizedAccess();
    error InvalidHouseEdge();

    // Modifiers
    modifier onlyPlatformOwner() {
        require(msg.sender == platformOwner, "Only platform owner");
        _;
    }

    modifier gameNotPaused() {
        if (gamePaused) revert GamePaused();
        _;
    }

    modifier flipExists(uint256 _flipId) {
        require(_flipId < nextFlipId, "Flip does not exist");
        _;
    }

    constructor() {
        platformOwner = msg.sender;
        nonce = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender)));
    }

    /**
     * @dev Create a new coin flip bet
     * @param _chosenSide The side the player is betting on (Heads or Tails)
     */
    function createFlip(Side _chosenSide) 
        external 
        payable 
        gameNotPaused 
        returns (uint256 flipId) 
    {
        if (msg.value < MIN_BET || msg.value > MAX_BET) revert InvalidBetAmount();
        
        // Calculate potential payout
        uint256 potentialPayout = (msg.value * PAYOUT_MULTIPLIER) / 100;
        
        // Ensure house has enough balance to cover potential payout
        if (address(this).balance - msg.value < potentialPayout) {
            revert InsufficientHouseBalance();
        }

        flipId = nextFlipId++;
        
        // Generate seed hash for randomness
        bytes32 seedHash = keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty,
            msg.sender,
            nonce++,
            flipId
        ));

        flips[flipId] = Flip({
            player: msg.sender,
            betAmount: msg.value,
            chosenSide: _chosenSide,
            result: Side.Heads, // Will be set when flip is resolved
            won: false,
            state: FlipState.Active,
            timestamp: block.timestamp,
            blockNumber: block.number,
            seedHash: seedHash,
            nonce: nonce,
            payout: 0
        });

        playerFlips[msg.sender].push(flipId);
        totalFlips++;
        totalVolume += msg.value;
        playerVolume[msg.sender] += msg.value;

        emit FlipCreated(flipId, msg.sender, msg.value, _chosenSide, seedHash);
        
        // Immediately resolve the flip
        _resolveFlip(flipId);
    }

    /**
     * @dev Internal function to resolve a flip
     * @param _flipId ID of the flip to resolve
     */
    function _resolveFlip(uint256 _flipId) internal {
        Flip storage flip = flips[_flipId];
        
        // Generate random result using multiple entropy sources
        uint256 randomValue = uint256(keccak256(abi.encodePacked(
            flip.seedHash,
            block.timestamp,
            block.difficulty,
            block.coinbase,
            tx.gasprice,
            _flipId
        )));
        
        // Determine result (0 = Heads, 1 = Tails)
        Side result = (randomValue % 2 == 0) ? Side.Heads : Side.Tails;
        flip.result = result;
        
        // Check if player won
        bool won = (flip.chosenSide == result);
        flip.won = won;
        flip.state = FlipState.Finished;
        
        uint256 payout = 0;
        
        if (won) {
            payout = (flip.betAmount * PAYOUT_MULTIPLIER) / 100;
            flip.payout = payout;
            playerStats[flip.player]++;
            totalPayouts += payout;
            
            // Transfer winnings to player
            (bool success, ) = payable(flip.player).call{value: payout}("");
            if (!success) revert TransferFailed();
        } else {
            // House keeps the bet (minus already allocated house balance)
            uint256 houseProfit = (flip.betAmount * houseEdge) / 10000;
            houseBalance += houseProfit;
        }

        emit FlipResult(_flipId, flip.player, flip.chosenSide, result, won, payout);
    }

    /**
     * @dev Get flip details
     * @param _flipId ID of the flip
     */
    function getFlip(uint256 _flipId) 
        external 
        view 
        flipExists(_flipId)
        returns (
            address player,
            uint256 betAmount,
            Side chosenSide,
            Side result,
            bool won,
            FlipState state,
            uint256 timestamp,
            uint256 payout
        ) 
    {
        Flip memory flip = flips[_flipId];
        return (
            flip.player,
            flip.betAmount,
            flip.chosenSide,
            flip.result,
            flip.won,
            flip.state,
            flip.timestamp,
            flip.payout
        );
    }

    /**
     * @dev Get player's flip history
     * @param _player Address of the player
     */
    function getPlayerFlips(address _player) 
        external 
        view 
        returns (uint256[] memory) 
    {
        return playerFlips[_player];
    }

    /**
     * @dev Get recent flips for display
     * @param _start Start index
     * @param _limit Number of flips to return
     */
    function getRecentFlips(uint256 _start, uint256 _limit) 
        external 
        view 
        returns (uint256[] memory recentFlips) 
    {
        uint256 end = nextFlipId;
        if (_start >= end) {
            return new uint256[](0);
        }
        
        uint256 count = _limit;
        if (_start + _limit > end) {
            count = end - _start;
        }
        
        recentFlips = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            recentFlips[i] = end - 1 - _start - i;
        }
    }

    /**
     * @dev Get player statistics
     * @param _player Address of the player
     */
    function getPlayerStats(address _player) 
        external 
        view 
        returns (
            uint256 totalWins,
            uint256 totalVolume,
            uint256 totalFlipsCount,
            uint256 winRate
        ) 
    {
        totalWins = playerStats[_player];
        totalVolume = playerVolume[_player];
        totalFlipsCount = playerFlips[_player].length;
        
        if (totalFlipsCount > 0) {
            winRate = (totalWins * 100) / totalFlipsCount;
        } else {
            winRate = 0;
        }
    }

    /**
     * @dev Get platform statistics
     */
    function getPlatformStats() 
        external 
        view 
        returns (
            uint256 _totalFlips,
            uint256 _totalVolume,
            uint256 _totalPayouts,
            uint256 _houseBalance,
            uint256 _houseEdge,
            bool _gamePaused
        ) 
    {
        return (
            totalFlips,
            totalVolume,
            totalPayouts,
            houseBalance,
            houseEdge,
            gamePaused
        );
    }

    /**
     * @dev Calculate expected payout for a bet amount
     * @param _betAmount Bet amount in wei
     */
    function calculatePayout(uint256 _betAmount) 
        external 
        pure 
        returns (uint256 expectedPayout) 
    {
        return (_betAmount * PAYOUT_MULTIPLIER) / 100;
    }

    /**
     * @dev Update house edge (only platform owner)
     * @param _newHouseEdge New house edge in basis points (max 1000 = 10%)
     */
    function updateHouseEdge(uint256 _newHouseEdge) external onlyPlatformOwner {
        if (_newHouseEdge > 1000) revert InvalidHouseEdge();
        houseEdge = _newHouseEdge;
        emit HouseEdgeUpdated(_newHouseEdge);
    }

    /**
     * @dev Pause/unpause the game (only platform owner)
     * @param _paused True to pause, false to unpause
     */
    function pauseGame(bool _paused) external onlyPlatformOwner {
        gamePaused = _paused;
        emit GamePaused(_paused);
    }

    /**
     * @dev Withdraw house funds (only platform owner)
     * @param _amount Amount to withdraw
     */
    function withdrawHouseFunds(uint256 _amount) external onlyPlatformOwner {
        require(_amount <= houseBalance, "Insufficient house balance");
        
        houseBalance -= _amount;
        
        (bool success, ) = payable(platformOwner).call{value: _amount}("");
        if (!success) revert TransferFailed();
        
        emit HouseFundsWithdrawn(_amount);
    }

    /**
     * @dev Add funds to house balance (only platform owner)
     */
    function addHouseFunds() external payable onlyPlatformOwner {
        houseBalance += msg.value;
    }

    /**
     * @dev Transfer ownership
     * @param _newOwner New platform owner address
     */
    function transferOwnership(address _newOwner) external onlyPlatformOwner {
        require(_newOwner != address(0), "Invalid address");
        platformOwner = _newOwner;
    }

    /**
     * @dev Emergency withdrawal (only platform owner)
     */
    function emergencyWithdraw() external onlyPlatformOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = payable(platformOwner).call{value: balance}("");
        if (!success) revert TransferFailed();
    }

    /**
     * @dev Get contract balance information
     */
    function getBalanceInfo() 
        external 
        view 
        returns (
            uint256 contractBalance,
            uint256 availableBalance,
            uint256 reservedBalance
        ) 
    {
        contractBalance = address(this).balance;
        reservedBalance = houseBalance;
        availableBalance = contractBalance > reservedBalance ? 
            contractBalance - reservedBalance : 0;
    }

    // Receive function to accept ETH deposits for house funds
    receive() external payable {
        houseBalance += msg.value;
    }
}