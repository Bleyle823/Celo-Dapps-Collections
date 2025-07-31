pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title TokenGatedPage
 * @dev A smart contract that gates access to content based on token ownership
 */
contract TokenGatedPage is Ownable, ReentrancyGuard {
    // The token required for access
    IERC20 public gatingToken;
    
    // Minimum token balance required for access
    uint256 public minimumTokenBalance;
    
    // Mapping to store premium content access
    mapping(address => bool) public hasAccess;
    
    // Mapping to store user access timestamps
    mapping(address => uint256) public lastAccessTime;
    
    // Events
    event AccessGranted(address indexed user, uint256 timestamp);
    event AccessRevoked(address indexed user, uint256 timestamp);
    event TokenRequirementUpdated(uint256 newMinimum);
    event GatingTokenUpdated(address newToken);
    
    // Custom errors
    error InsufficientTokenBalance(uint256 required, uint256 actual);
    error AlreadyHasAccess();
    error NoAccessToRevoke();
    error InvalidTokenAddress();
    
    /**
     * @dev Constructor
     * @param _gatingToken Address of the ERC20 token used for gating
     * @param _minimumBalance Minimum token balance required for access
     */
    constructor(
        address _gatingToken,
        uint256 _minimumBalance
    ) {
        if (_gatingToken == address(0)) revert InvalidTokenAddress();
        
        gatingToken = IERC20(_gatingToken);
        minimumTokenBalance = _minimumBalance;
    }
    
    /**
     * @dev Modifier to check if user has sufficient tokens
     */
    modifier hasRequiredTokens() {
        uint256 userBalance = gatingToken.balanceOf(msg.sender);
        if (userBalance < minimumTokenBalance) {
            revert InsufficientTokenBalance(minimumTokenBalance, userBalance);
        }
        _;
    }
    
    /**
     * @dev Modifier to check if user has access
     */
    modifier onlyWithAccess() {
        require(hasAccess[msg.sender], "Access denied: insufficient token balance");
        _;
    }
    
    /**
     * @dev Request access to the gated content
     * User must hold minimum required tokens
     */
    function requestAccess() external hasRequiredTokens nonReentrant {
        if (hasAccess[msg.sender]) revert AlreadyHasAccess();
        
        hasAccess[msg.sender] = true;
        lastAccessTime[msg.sender] = block.timestamp;
        
        emit AccessGranted(msg.sender, block.timestamp);
    }
    
    /**
     * @dev Check if user currently has access (validates token balance)
     * @param user Address to check
     * @return bool indicating if user has access
     */
    function checkAccess(address user) external view returns (bool) {
        if (!hasAccess[user]) return false;
        
        uint256 userBalance = gatingToken.balanceOf(user);
        return userBalance >= minimumTokenBalance;
    }
    
    /**
     * @dev Revoke access for users who no longer meet requirements
     * Can be called by anyone to clean up invalid access
     * @param user Address to check and potentially revoke
     */
    function revokeAccessIfIneligible(address user) external {
        if (!hasAccess[user]) revert NoAccessToRevoke();
        
        uint256 userBalance = gatingToken.balanceOf(user);
        if (userBalance < minimumTokenBalance) {
            hasAccess[user] = false;
            emit AccessRevoked(user, block.timestamp);
        }
    }
    
    /**
     * @dev Access premium content (example function)
     * @return string Premium content for token holders
     */
    function getPremiumContent() external view onlyWithAccess returns (string memory) {
        // Verify user still has required tokens
        uint256 userBalance = gatingToken.balanceOf(msg.sender);
        require(userBalance >= minimumTokenBalance, "Token balance too low");
        
        return "Welcome to the exclusive token-gated content! You have proven your token ownership.";
    }
    
    /**
     * @dev Get user's current token balance
     * @param user Address to check
     * @return uint256 Current token balance
     */
    function getUserTokenBalance(address user) external view returns (uint256) {
        return gatingToken.balanceOf(user);
    }
    
    /**
     * @dev Get access status and requirements
     * @param user Address to check
     * @return hasCurrentAccess Whether user currently has access
     * @return tokenBalance User's current token balance
     * @return requiredBalance Required token balance
     */
    function getAccessInfo(address user) external view returns (
        bool hasCurrentAccess,
        uint256 tokenBalance,
        uint256 requiredBalance
    ) {
        tokenBalance = gatingToken.balanceOf(user);
        requiredBalance = minimumTokenBalance;
        hasCurrentAccess = hasAccess[user] && tokenBalance >= requiredBalance;
    }
    
    // Owner-only functions
    
    /**
     * @dev Update minimum token balance requirement
     * @param _newMinimum New minimum token balance
     */
    function updateMinimumBalance(uint256 _newMinimum) external onlyOwner {
        minimumTokenBalance = _newMinimum;
        emit TokenRequirementUpdated(_newMinimum);
    }
    
    /**
     * @dev Update the gating token address
     * @param _newToken New token contract address
     */
    function updateGatingToken(address _newToken) external onlyOwner {
        if (_newToken == address(0)) revert InvalidTokenAddress();
        
        gatingToken = IERC20(_newToken);
        emit GatingTokenUpdated(_newToken);
    }
    
    /**
     * @dev Emergency revoke access for a specific user
     * @param user Address to revoke access from
     */
    function emergencyRevokeAccess(address user) external onlyOwner {
        if (!hasAccess[user]) revert NoAccessToRevoke();
        
        hasAccess[user] = false;
        emit AccessRevoked(user, block.timestamp);
    }
    
    /**
     * @dev Get contract information
     * @return tokenAddress Address of the gating token
     * @return minimumRequired Minimum token balance required
     * @return contractOwner Owner of this contract
     */
    function getContractInfo() external view returns (
        address tokenAddress,
        uint256 minimumRequired,
        address contractOwner
    ) {
        return (address(gatingToken), minimumTokenBalance, owner());
    }
}