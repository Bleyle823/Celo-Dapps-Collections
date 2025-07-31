// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title RockPaperScissors
 * @dev A provably fair Rock Paper Scissors game with betting and commitment-reveal scheme
 */
contract RockPaperScissors {
    enum Choice { None, Rock, Paper, Scissors }
    enum GameState { Open, Committed, Revealed, Finished }
    
    struct Game {
        address player1;
        address player2;
        uint256 betAmount;
        bytes32 player1Commitment;
        bytes32 player2Commitment;
        Choice player1Choice;
        Choice player2Choice;
        GameState state;
        address winner;
        uint256 createdAt;
        uint256 deadline;
        bool prizeClaimed;
    }

    // State variables
    mapping(uint256 => Game) public games;
    mapping(address => uint256[]) public playerGames;
    mapping(address => uint256) public playerStats; // wins count
    
    uint256 public nextGameId;
    uint256 public totalGames;
    uint256 public totalVolume;
    
    // Platform fee (in basis points, 100 = 1%)
    uint256 public platformFee = 200; // 2%
    address public platformOwner;
    uint256 public platformBalance;
    
    // Game settings
    uint256 public constant REVEAL_TIMEOUT = 1 hours;
    uint256 public constant MIN_BET = 0.001 ether;
    uint256 public constant MAX_BET = 10 ether;

    // Events
    event GameCreated(
        uint256 indexed gameId,
        address indexed player1,
        uint256 betAmount,
        uint256 deadline
    );
    
    event PlayerJoined(
        uint256 indexed gameId,
        address indexed player2
    );
    
    event CommitmentMade(
        uint256 indexed gameId,
        address indexed player,
        bytes32 commitment
    );
    
    event ChoiceRevealed(
        uint256 indexed gameId,
        address indexed player,
        Choice choice
    );
    
    event GameFinished(
        uint256 indexed gameId,
        address indexed winner,
        Choice player1Choice,
        Choice player2Choice,
        uint256 prize
    );
    
    event PrizeClaimed(
        uint256 indexed gameId,
        address indexed winner,
        uint256 amount
    );

    // Errors
    error InvalidBetAmount();
    error GameNotOpen();
    error GameNotInCommitPhase();
    error GameNotInRevealPhase();
    error PlayerAlreadyInGame();
    error NotGamePlayer();
    error InvalidChoice();
    error InvalidCommitment();
    error RevealTimeoutNotReached();
    error PrizeAlreadyClaimed();
    error TransferFailed();
    error GameExpired();
    error UnauthorizedAccess();

    // Modifiers
    modifier onlyPlatformOwner() {
        require(msg.sender == platformOwner, "Only platform owner");
        _;
    }

    modifier gameExists(uint256 _gameId) {
        require(_gameId < nextGameId, "Game does not exist");
        _;
    }

    modifier onlyGamePlayer(uint256 _gameId) {
        Game memory game = games[_gameId];
        require(msg.sender == game.player1 || msg.sender == game.player2, "Not a game player");
        _;
    }

    constructor() {
        platformOwner = msg.sender;
    }

    /**
     * @dev Create a new Rock Paper Scissors game
     * @param _commitment Player 1's commitment (hash of choice + nonce)
     */
    function createGame(bytes32 _commitment) external payable returns (uint256 gameId) {
        if (msg.value < MIN_BET || msg.value > MAX_BET) revert InvalidBetAmount();
        require(_commitment != bytes32(0), "Invalid commitment");

        gameId = nextGameId++;
        
        games[gameId] = Game({
            player1: msg.sender,
            player2: address(0),
            betAmount: msg.value,
            player1Commitment: _commitment,
            player2Commitment: bytes32(0),
            player1Choice: Choice.None,
            player2Choice: Choice.None,
            state: GameState.Open,
            winner: address(0),
            createdAt: block.timestamp,
            deadline: block.timestamp + REVEAL_TIMEOUT,
            prizeClaimed: false
        });

        playerGames[msg.sender].push(gameId);
        totalGames++;

        emit GameCreated(gameId, msg.sender, msg.value, games[gameId].deadline);
    }

    /**
     * @dev Join an existing game as player 2
     * @param _gameId ID of the game to join
     * @param _commitment Player 2's commitment
     */
    function joinGame(uint256 _gameId, bytes32 _commitment) 
        external 
        payable 
        gameExists(_gameId) 
    {
        Game storage game = games[_gameId];
        
        if (game.state != GameState.Open) revert GameNotOpen();
        require(msg.sender != game.player1, "Cannot play against yourself");
        require(msg.value == game.betAmount, "Must match bet amount");
        require(_commitment != bytes32(0), "Invalid commitment");

        game.player2 = msg.sender;
        game.player2Commitment = _commitment;
        game.state = GameState.Committed;
        game.deadline = block.timestamp + REVEAL_TIMEOUT;

        playerGames[msg.sender].push(_gameId);
        totalVolume += msg.value * 2;

        emit PlayerJoined(_gameId, msg.sender);
    }

    /**
     * @dev Reveal player's choice
     * @param _gameId ID of the game
     * @param _choice Player's actual choice
     * @param _nonce Nonce used in commitment
     */
    function revealChoice(uint256 _gameId, Choice _choice, uint256 _nonce) 
        external 
        gameExists(_gameId)
        onlyGamePlayer(_gameId)
    {
        Game storage game = games[_gameId];
        
        if (game.state != GameState.Committed && game.state != GameState.Revealed) {
            revert GameNotInRevealPhase();
        }
        
        if (_choice == Choice.None || _choice > Choice.Scissors) revert InvalidChoice();

        bytes32 commitment = keccak256(abi.encodePacked(_choice, _nonce, msg.sender));
        
        if (msg.sender == game.player1) {
            if (commitment != game.player1Commitment) revert InvalidCommitment();
            require(game.player1Choice == Choice.None, "Already revealed");
            game.player1Choice = _choice;
        } else {
            if (commitment != game.player2Commitment) revert InvalidCommitment();
            require(game.player2Choice == Choice.None, "Already revealed");
            game.player2Choice = _choice;
        }

        emit ChoiceRevealed(_gameId, msg.sender, _choice);

        // Check if both players have revealed
        if (game.player1Choice != Choice.None && game.player2Choice != Choice.None) {
            _finishGame(_gameId);
        } else if (game.state == GameState.Committed) {
            game.state = GameState.Revealed;
        }
    }

    /**
     * @dev Claim prize for timeout (if opponent doesn't reveal in time)
     * @param _gameId ID of the game
     */
    function claimTimeoutPrize(uint256 _gameId) 
        external 
        gameExists(_gameId)
        onlyGamePlayer(_gameId)
    {
        Game storage game = games[_gameId];
        
        require(block.timestamp > game.deadline, "Timeout not reached");
        require(game.state == GameState.Revealed, "Game not in reveal phase");
        require(!game.prizeClaimed, "Prize already claimed");

        // Determine winner based on who revealed
        address winner;
        if (game.player1Choice != Choice.None && game.player2Choice == Choice.None) {
            winner = game.player1;
        } else if (game.player2Choice != Choice.None && game.player1Choice == Choice.None) {
            winner = game.player2;
        } else {
            revert("Invalid timeout claim");
        }

        require(msg.sender == winner, "Only winner can claim");

        game.winner = winner;
        game.state = GameState.Finished;
        game.prizeClaimed = true;

        uint256 totalPot = game.betAmount * 2;
        uint256 fee = (totalPot * platformFee) / 10000;
        uint256 prize = totalPot - fee;

        platformBalance += fee;
        playerStats[winner]++;

        (bool success, ) = payable(winner).call{value: prize}("");
        if (!success) revert TransferFailed();

        emit PrizeClaimed(_gameId, winner, prize);
    }

    /**
     * @dev Internal function to finish game and determine winner
     */
    function _finishGame(uint256 _gameId) internal {
        Game storage game = games[_gameId];
        
        address winner = _determineWinner(game.player1Choice, game.player2Choice);
        
        game.winner = winner;
        game.state = GameState.Finished;
        
        uint256 totalPot = game.betAmount * 2;
        uint256 fee = (totalPot * platformFee) / 10000;
        uint256 prize = totalPot - fee;
        
        platformBalance += fee;

        if (winner != address(0)) {
            playerStats[winner]++;
            (bool success, ) = payable(winner).call{value: prize}("");
            if (!success) revert TransferFailed();
        } else {
            // Tie - refund both players minus platform fee
            uint256 refundAmount = (prize / 2);
            
            (bool success1, ) = payable(game.player1).call{value: refundAmount}("");
            (bool success2, ) = payable(game.player2).call{value: refundAmount}("");
            
            if (!success1 || !success2) revert TransferFailed();
        }
        
        game.prizeClaimed = true;

        emit GameFinished(
            _gameId, 
            winner, 
            game.player1Choice, 
            game.player2Choice, 
            prize
        );
    }

    /**
     * @dev Determine winner based on choices
     * @param _choice1 Player 1's choice
     * @param _choice2 Player 2's choice
     * @return winner Address of winner, or address(0) for tie
     */
    function _determineWinner(Choice _choice1, Choice _choice2) 
        internal 
        view
        returns (address winner) 
    {
        if (_choice1 == _choice2) {
            return address(0); // Tie
        }
        
        Game storage game = games[0]; // Just to get player addresses
        
        if ((_choice1 == Choice.Rock && _choice2 == Choice.Scissors) ||
            (_choice1 == Choice.Paper && _choice2 == Choice.Rock) ||
            (_choice1 == Choice.Scissors && _choice2 == Choice.Paper)) {
            return game.player1;
        } else {
            return game.player2;
        }
    }

    /**
     * @dev Get game details
     */
    function getGame(uint256 _gameId) 
        external 
        view 
        gameExists(_gameId)
        returns (
            address player1,
            address player2,
            uint256 betAmount,
            GameState state,
            Choice player1Choice,
            Choice player2Choice,
            address winner,
            uint256 deadline,
            bool prizeClaimed
        ) 
    {
        Game memory game = games[_gameId];
        return (
            game.player1,
            game.player2,
            game.betAmount,
            game.state,
            game.player1Choice,
            game.player2Choice,
            game.winner,
            game.deadline,
            game.prizeClaimed
        );
    }

    /**
     * @dev Get player's game history
     */
    function getPlayerGames(address _player) 
        external 
        view 
        returns (uint256[] memory) 
    {
        return playerGames[_player];
    }

    /**
     * @dev Get open games for joining
     */
    function getOpenGames(uint256 _start, uint256 _limit) 
        external 
        view 
        returns (uint256[] memory openGames) 
    {
        uint256[] memory temp = new uint256[](nextGameId);
        uint256 count = 0;
        
        for (uint256 i = _start; i < nextGameId && count < _limit; i++) {
            if (games[i].state == GameState.Open) {
                temp[count] = i;
                count++;
            }
        }
        
        openGames = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            openGames[i] = temp[i];
        }
    }

    /**
     * @dev Generate commitment hash for frontend
     * @param _choice Player's choice
     * @param _nonce Random nonce
     * @param _player Player's address
     */
    function generateCommitment(Choice _choice, uint256 _nonce, address _player) 
        external 
        pure 
        returns (bytes32) 
    {
        return keccak256(abi.encodePacked(_choice, _nonce, _player));
    }

    /**
     * @dev Update platform fee (only owner)
     */
    function updatePlatformFee(uint256 _newFee) external onlyPlatformOwner {
        require(_newFee <= 1000, "Fee too high"); // Max 10%
        platformFee = _newFee;
    }

    /**
     * @dev Withdraw platform fees
     */
    function withdrawPlatformFees() external onlyPlatformOwner {
        uint256 amount = platformBalance;
        platformBalance = 0;
        
        (bool success, ) = payable(platformOwner).call{value: amount}("");
        if (!success) revert TransferFailed();
    }

    /**
     * @dev Get platform statistics
     */
    function getPlatformStats() external view returns (
        uint256 _totalGames,
        uint256 _totalVolume,
        uint256 _platformFee,
        uint256 _platformBalance
    ) {
        return (totalGames, totalVolume, platformFee, platformBalance);
    }

    /**
     * @dev Get player statistics
     */
    function getPlayerStats(address _player) external view returns (uint256 wins) {
        return playerStats[_player];
    }

    /**
     * @dev Transfer ownership
     */
    function transferOwnership(address _newOwner) external onlyPlatformOwner {
        require(_newOwner != address(0), "Invalid address");
        platformOwner = _newOwner;
    }
}