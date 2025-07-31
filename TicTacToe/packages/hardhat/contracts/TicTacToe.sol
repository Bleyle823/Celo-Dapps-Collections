pragma solidity ^0.8.19;

/**
 * @title TicTacToe
 * @dev A simple TicTacToe game smart contract for two players
 */
contract TicTacToe {
    // Game states
    enum GameState { WaitingForPlayer, InProgress, Finished }
    enum CellState { Empty, X, O }
    
    // Game structure
    struct Game {
        address playerX;
        address playerO;
        address currentPlayer;
        address winner;
        GameState state;
        CellState[3][3] board;
        uint256 moveCount;
        uint256 gameId;
    }
    
    // State variables
    mapping(uint256 => Game) public games;
    mapping(address => uint256[]) public playerGames;
    uint256 public gameCounter;
    
    // Events
    event GameCreated(uint256 indexed gameId, address indexed creator);
    event PlayerJoined(uint256 indexed gameId, address indexed player);
    event MoveMade(uint256 indexed gameId, address indexed player, uint8 row, uint8 col);
    event GameWon(uint256 indexed gameId, address indexed winner);
    event GameDraw(uint256 indexed gameId);
    
    // Custom errors
    error GameNotFound();
    error GameFull();
    error NotYourTurn();
    error InvalidMove();
    error GameNotInProgress();
    error AlreadyInGame();
    
    /**
     * @dev Create a new game
     * @return gameId The ID of the newly created game
     */
    function createGame() external returns (uint256) {
        uint256 gameId = gameCounter++;
        
        Game storage newGame = games[gameId];
        newGame.playerX = msg.sender;
        newGame.currentPlayer = msg.sender;
        newGame.state = GameState.WaitingForPlayer;
        newGame.gameId = gameId;
        
        // Initialize empty board
        for (uint8 i = 0; i < 3; i++) {
            for (uint8 j = 0; j < 3; j++) {
                newGame.board[i][j] = CellState.Empty;
            }
        }
        
        playerGames[msg.sender].push(gameId);
        
        emit GameCreated(gameId, msg.sender);
        return gameId;
    }
    
    /**
     * @dev Join an existing game as player O
     * @param gameId The ID of the game to join
     */
    function joinGame(uint256 gameId) external {
        Game storage game = games[gameId];
        
        if (game.playerX == address(0)) revert GameNotFound();
        if (game.playerO != address(0)) revert GameFull();
        if (game.playerX == msg.sender) revert AlreadyInGame();
        
        game.playerO = msg.sender;
        game.state = GameState.InProgress;
        
        playerGames[msg.sender].push(gameId);
        
        emit PlayerJoined(gameId, msg.sender);
    }
    
    /**
     * @dev Make a move in the game
     * @param gameId The ID of the game
     * @param row Row position (0-2)
     * @param col Column position (0-2)
     */
    function makeMove(uint256 gameId, uint8 row, uint8 col) external {
        Game storage game = games[gameId];
        
        // Validation checks
        if (game.state != GameState.InProgress) revert GameNotInProgress();
        if (msg.sender != game.currentPlayer) revert NotYourTurn();
        if (row > 2 || col > 2) revert InvalidMove();
        if (game.board[row][col] != CellState.Empty) revert InvalidMove();
        
        // Make the move
        CellState symbol = (msg.sender == game.playerX) ? CellState.X : CellState.O;
        game.board[row][col] = symbol;
        game.moveCount++;
        
        emit MoveMade(gameId, msg.sender, row, col);
        
        // Check for winner
        if (checkWinner(gameId, symbol)) {
            game.winner = msg.sender;
            game.state = GameState.Finished;
            emit GameWon(gameId, msg.sender);
            return;
        }
        
        // Check for draw
        if (game.moveCount == 9) {
            game.state = GameState.Finished;
            emit GameDraw(gameId);
            return;
        }
        
        // Switch turns
        game.currentPlayer = (game.currentPlayer == game.playerX) ? game.playerO : game.playerX;
    }
    
    /**
     * @dev Check if there's a winner
     * @param gameId The ID of the game
     * @param symbol The symbol to check for winning
     * @return bool True if the symbol has won
     */
    function checkWinner(uint256 gameId, CellState symbol) internal view returns (bool) {
        CellState[3][3] storage board = games[gameId].board;
        
        // Check rows
        for (uint8 i = 0; i < 3; i++) {
            if (board[i][0] == symbol && board[i][1] == symbol && board[i][2] == symbol) {
                return true;
            }
        }
        
        // Check columns
        for (uint8 j = 0; j < 3; j++) {
            if (board[0][j] == symbol && board[1][j] == symbol && board[2][j] == symbol) {
                return true;
            }
        }
        
        // Check diagonals
        if (board[0][0] == symbol && board[1][1] == symbol && board[2][2] == symbol) {
            return true;
        }
        
        if (board[0][2] == symbol && board[1][1] == symbol && board[2][0] == symbol) {
            return true;
        }
        
        return false;
    }
    
    /**
     * @dev Get the current board state
     * @param gameId The ID of the game
     * @return board The 3x3 board as a flattened array (0=Empty, 1=X, 2=O)
     */
    function getBoard(uint256 gameId) external view returns (uint8[9] memory board) {
        Game storage game = games[gameId];
        uint8 index = 0;
        
        for (uint8 i = 0; i < 3; i++) {
            for (uint8 j = 0; j < 3; j++) {
                board[index] = uint8(game.board[i][j]);
                index++;
            }
        }
    }
    
    /**
     * @dev Get game information
     * @param gameId The ID of the game
     * @return playerX Address of player X
     * @return playerO Address of player O
     * @return currentPlayer Address of current player
     * @return winner Address of winner (zero address if no winner)
     * @return state Current game state
     * @return moveCount Number of moves made
     */
    function getGameInfo(uint256 gameId) external view returns (
        address playerX,
        address playerO,
        address currentPlayer,
        address winner,
        GameState state,
        uint256 moveCount
    ) {
        Game storage game = games[gameId];
        return (
            game.playerX,
            game.playerO,
            game.currentPlayer,
            game.winner,
            game.state,
            game.moveCount
        );
    }
    
    /**
     * @dev Get all games for a player
     * @param player The player's address
     * @return gameIds Array of game IDs the player has participated in
     */
    function getPlayerGames(address player) external view returns (uint256[] memory) {
        return playerGames[player];
    }
    
    /**
     * @dev Check if it's a specific player's turn
     * @param gameId The ID of the game
     * @param player The player to check
     * @return bool True if it's the player's turn
     */
    function isPlayerTurn(uint256 gameId, address player) external view returns (bool) {
        Game storage game = games[gameId];
        return game.currentPlayer == player && game.state == GameState.InProgress;
    }
    
    /**
     * @dev Get the symbol for a player in a specific game
     * @param gameId The ID of the game
     * @param player The player's address
     * @return symbol The player's symbol (1=X, 2=O, 0=Not in game)
     */
    function getPlayerSymbol(uint256 gameId, address player) external view returns (uint8) {
        Game storage game = games[gameId];
        
        if (game.playerX == player) return 1; // X
        if (game.playerO == player) return 2; // O
        return 0; // Not in game
    }
    
    /**
     * @dev Get total number of games created
     * @return uint256 Total game count
     */
    function getTotalGames() external view returns (uint256) {
        return gameCounter;
    }
}