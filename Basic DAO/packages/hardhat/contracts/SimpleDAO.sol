// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title SimpleDAO
 * @dev A simple DAO contract with proposal creation, voting, and execution
 */
contract SimpleDAO is ReentrancyGuard, Ownable {
    // Governance token
    IERC20 public governanceToken;
    
    // Proposal structure
    struct Proposal {
        uint256 id;
        address proposer;
        string title;
        string description;
        address target;
        uint256 value;
        bytes data;
        uint256 startTime;
        uint256 endTime;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 votesAbstain;
        bool executed;
        bool canceled;
        ProposalState state;
    }
    
    // Vote structure
    struct Vote {
        bool hasVoted;
        VoteType voteType;
        uint256 weight;
        uint256 timestamp;
    }
    
    // Enums
    enum ProposalState { Pending, Active, Succeeded, Defeated, Executed, Canceled }
    enum VoteType { Against, For, Abstain }
    
    // State variables
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => Vote)) public votes;
    mapping(address => uint256) public membershipTimestamp;
    
    uint256 public proposalCounter;
    uint256 public votingDelay = 1 days; // Time before voting starts
    uint256 public votingPeriod = 7 days; // Voting duration
    uint256 public proposalThreshold = 1000 * 10**18; // Min tokens to propose
    uint256 public quorumThreshold = 10; // 10% of total supply
    uint256 public passingThreshold = 50; // 50% of votes needed to pass
    
    // Treasury
    uint256 public treasuryBalance;
    
    // Events
    event ProposalCreated(
        uint256 indexed proposalId,
        address indexed proposer,
        string title,
        uint256 startTime,
        uint256 endTime
    );
    event VoteCast(
        uint256 indexed proposalId,
        address indexed voter,
        VoteType voteType,
        uint256 weight
    );
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalCanceled(uint256 indexed proposalId);
    event MemberJoined(address indexed member, uint256 timestamp);
    event FundsDeposited(address indexed depositor, uint256 amount);
    event FundsWithdrawn(address indexed recipient, uint256 amount);
    
    // Custom errors
    error InsufficientTokens(uint256 required, uint256 actual);
    error ProposalNotActive();
    error AlreadyVoted();
    error ProposalNotSucceeded();
    error ProposalAlreadyExecuted();
    error ExecutionFailed();
    error NotAuthorized();
    error InvalidProposal();
    error InsufficientTreasuryFunds();
    
    /**
     * @dev Constructor
     * @param _governanceToken Address of the governance token
     */
    constructor(address _governanceToken) Ownable(msg.sender) {
        require(_governanceToken != address(0), "Invalid token address");
        governanceToken = IERC20(_governanceToken);
        treasuryBalance = 0;
    }
    
    /**
     * @dev Join the DAO as a member
     */
    function joinDAO() external {
        require(governanceToken.balanceOf(msg.sender) > 0, "Must hold governance tokens");
        
        if (membershipTimestamp[msg.sender] == 0) {
            membershipTimestamp[msg.sender] = block.timestamp;
            emit MemberJoined(msg.sender, block.timestamp);
        }
    }
    
    /**
     * @dev Create a new proposal
     * @param title Proposal title
     * @param description Proposal description
     * @param target Target contract address (use address(0) for treasury operations)
     * @param value ETH value to send
     * @param data Call data
     */
    function createProposal(
        string memory title,
        string memory description,
        address target,
        uint256 value,
        bytes memory data
    ) public returns (uint256) {
        uint256 proposerBalance = governanceToken.balanceOf(msg.sender);
        if (proposerBalance < proposalThreshold) {
            revert InsufficientTokens(proposalThreshold, proposerBalance);
        }
        
        require(membershipTimestamp[msg.sender] != 0, "Must be a DAO member");
        require(bytes(title).length > 0, "Title cannot be empty");
        
        uint256 proposalId = proposalCounter++;
        uint256 startTime = block.timestamp + votingDelay;
        uint256 endTime = startTime + votingPeriod;
        
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            title: title,
            description: description,
            target: target,
            value: value,
            data: data,
            startTime: startTime,
            endTime: endTime,
            votesFor: 0,
            votesAgainst: 0,
            votesAbstain: 0,
            executed: false,
            canceled: false,
            state: ProposalState.Pending
        });
        
        emit ProposalCreated(proposalId, msg.sender, title, startTime, endTime);
        return proposalId;
    }
    
    /**
     * @dev Cast a vote on a proposal
     * @param proposalId Proposal ID to vote on
     * @param voteType Vote type (0=Against, 1=For, 2=Abstain)
     */
    function castVote(uint256 proposalId, VoteType voteType) external {
        Proposal storage proposal = proposals[proposalId];
        
        require(proposal.proposer != address(0), "Proposal does not exist");
        require(block.timestamp >= proposal.startTime, "Voting not started");
        require(block.timestamp <= proposal.endTime, "Voting ended");
        require(membershipTimestamp[msg.sender] != 0, "Must be a DAO member");
        
        Vote storage vote = votes[proposalId][msg.sender];
        if (vote.hasVoted) revert AlreadyVoted();
        
        uint256 weight = governanceToken.balanceOf(msg.sender);
        require(weight > 0, "No voting power");
        
        vote.hasVoted = true;
        vote.voteType = voteType;
        vote.weight = weight;
        vote.timestamp = block.timestamp;
        
        if (voteType == VoteType.For) {
            proposal.votesFor += weight;
        } else if (voteType == VoteType.Against) {
            proposal.votesAgainst += weight;
        } else {
            proposal.votesAbstain += weight;
        }
        
        emit VoteCast(proposalId, msg.sender, voteType, weight);
    }
    
    /**
     * @dev Execute a successful proposal
     * @param proposalId Proposal ID to execute
     */
    function executeProposal(uint256 proposalId) external nonReentrant {
        Proposal storage proposal = proposals[proposalId];
        
        require(proposal.proposer != address(0), "Proposal does not exist");
        require(!proposal.executed, "Already executed");
        require(!proposal.canceled, "Proposal canceled");
        require(block.timestamp > proposal.endTime, "Voting still active");
        
        // Check if proposal succeeded
        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst + proposal.votesAbstain;
        uint256 totalSupply = governanceToken.totalSupply();
        uint256 quorumRequired = (totalSupply * quorumThreshold) / 100;
        
        require(totalVotes >= quorumRequired, "Quorum not reached");
        
        uint256 passingVotes = (totalVotes * passingThreshold) / 100;
        require(proposal.votesFor > passingVotes, "Proposal defeated");
        
        proposal.executed = true;
        proposal.state = ProposalState.Executed;
        
        // Execute the proposal
        if (proposal.target == address(0)) {
            // Treasury operation
            if (proposal.value > 0) {
                require(treasuryBalance >= proposal.value, "Insufficient treasury funds");
                treasuryBalance -= proposal.value;
                
                // Decode recipient from data
                address recipient = abi.decode(proposal.data, (address));
                payable(recipient).transfer(proposal.value);
                emit FundsWithdrawn(recipient, proposal.value);
            }
        } else {
            // External contract call
            (bool success, ) = proposal.target.call{value: proposal.value}(proposal.data);
            if (!success) revert ExecutionFailed();
        }
        
        emit ProposalExecuted(proposalId);
    }
    
    /**
     * @dev Cancel a proposal (only proposer or owner can cancel)
     * @param proposalId Proposal ID to cancel
     */
    function cancelProposal(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        
        require(proposal.proposer != address(0), "Proposal does not exist");
        require(!proposal.executed, "Already executed");
        require(!proposal.canceled, "Already canceled");
        require(
            msg.sender == proposal.proposer || msg.sender == owner(),
            "Not authorized to cancel"
        );
        
        proposal.canceled = true;
        proposal.state = ProposalState.Canceled;
        
        emit ProposalCanceled(proposalId);
    }
    
    /**
     * @dev Create a treasury withdrawal proposal
     * @param recipient Address to send funds to
     * @param amount Amount to withdraw
     * @param title Proposal title
     * @param description Proposal description
     */
    function createTreasuryWithdrawalProposal(
        address recipient,
        uint256 amount,
        string memory title,
        string memory description
    ) external returns (uint256) {
        require(amount <= treasuryBalance, "Amount exceeds treasury balance");
        require(recipient != address(0), "Invalid recipient");
        
        bytes memory data = abi.encode(recipient);
        return createProposal(title, description, address(0), amount, data);
    }
    
    /**
     * @dev Deposit funds to treasury
     */
    function depositToTreasury() external payable {
        require(msg.value > 0, "Must send ETH");
        treasuryBalance += msg.value;
        emit FundsDeposited(msg.sender, msg.value);
    }
    
    // View functions
    
    /**
     * @dev Get proposal details
     * @param proposalId Proposal ID
     * @return Proposal struct
     */
    function getProposal(uint256 proposalId) external view returns (Proposal memory) {
        return proposals[proposalId];
    }
    
    /**
     * @dev Get current proposal state
     * @param proposalId Proposal ID
     * @return ProposalState Current state
     */
    function getProposalState(uint256 proposalId) external view returns (ProposalState) {
        Proposal storage proposal = proposals[proposalId];
        
        if (proposal.canceled) return ProposalState.Canceled;
        if (proposal.executed) return ProposalState.Executed;
        if (block.timestamp < proposal.startTime) return ProposalState.Pending;
        if (block.timestamp <= proposal.endTime) return ProposalState.Active;
        
        // Check if succeeded
        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst + proposal.votesAbstain;
        uint256 totalSupply = governanceToken.totalSupply();
        uint256 quorumRequired = (totalSupply * quorumThreshold) / 100;
        
        if (totalVotes < quorumRequired) return ProposalState.Defeated;
        
        uint256 passingVotes = (totalVotes * passingThreshold) / 100;
        if (proposal.votesFor > passingVotes) return ProposalState.Succeeded;
        
        return ProposalState.Defeated;
    }
    
    /**
     * @dev Get vote details for a user on a proposal
     * @param proposalId Proposal ID
     * @param voter Voter address
     * @return Vote struct
     */
    function getVote(uint256 proposalId, address voter) external view returns (Vote memory) {
        return votes[proposalId][voter];
    }
    
    /**
     * @dev Get voting power of an address
     * @param account Address to check
     * @return uint256 Voting power (token balance)
     */
    function getVotingPower(address account) external view returns (uint256) {
        return governanceToken.balanceOf(account);
    }
    
    /**
     * @dev Check if address is a DAO member
     * @param account Address to check
     * @return bool True if member
     */
    function isMember(address account) external view returns (bool) {
        return membershipTimestamp[account] != 0;
    }
    
    /**
     * @dev Get proposal voting results
     * @param proposalId Proposal ID
     * @return votesFor Votes in favor
     * @return votesAgainst Votes against
     * @return votesAbstain Abstain votes
     * @return totalVotes Total votes cast
     */
    function getVotingResults(uint256 proposalId) external view returns (
        uint256 votesFor,
        uint256 votesAgainst,
        uint256 votesAbstain,
        uint256 totalVotes
    ) {
        Proposal storage proposal = proposals[proposalId];
        votesFor = proposal.votesFor;
        votesAgainst = proposal.votesAgainst;
        votesAbstain = proposal.votesAbstain;
        totalVotes = votesFor + votesAgainst + votesAbstain;
    }
    
    /**
     * @dev Get DAO settings
     * @return _votingDelay Voting delay in seconds
     * @return _votingPeriod Voting period in seconds
     * @return _proposalThreshold Minimum tokens required to create a proposal
     * @return _quorumThreshold Quorum threshold percentage
     * @return _passingThreshold Passing threshold percentage
     * @return _treasuryBalance Current treasury balance
     */
    function getDAOSettings() external view returns (
        uint256 _votingDelay,
        uint256 _votingPeriod,
        uint256 _proposalThreshold,
        uint256 _quorumThreshold,
        uint256 _passingThreshold,
        uint256 _treasuryBalance
    ) {
        return (
            votingDelay,
            votingPeriod,
            proposalThreshold,
            quorumThreshold,
            passingThreshold,
            treasuryBalance
        );
    }
    
    // Owner functions for governance parameter updates
    
    /**
     * @dev Update voting delay
     * @param newDelay New voting delay in seconds
     */
    function setVotingDelay(uint256 newDelay) external onlyOwner {
        require(newDelay <= 30 days, "Delay too long");
        votingDelay = newDelay;
    }
    
    /**
     * @dev Update voting period
     * @param newPeriod New voting period in seconds
     */
    function setVotingPeriod(uint256 newPeriod) external onlyOwner {
        require(newPeriod >= 1 days && newPeriod <= 30 days, "Invalid period");
        votingPeriod = newPeriod;
    }
    
    /**
     * @dev Update proposal threshold
     * @param newThreshold New proposal threshold in tokens
     */
    function setProposalThreshold(uint256 newThreshold) external onlyOwner {
        proposalThreshold = newThreshold;
    }
    
    /**
     * @dev Update quorum threshold
     * @param newThreshold New quorum threshold percentage (1-100)
     */
    function setQuorumThreshold(uint256 newThreshold) external onlyOwner {
        require(newThreshold > 0 && newThreshold <= 100, "Invalid threshold");
        quorumThreshold = newThreshold;
    }
    
    /**
     * @dev Update passing threshold
     * @param newThreshold New passing threshold percentage (1-100)
     */
    function setPassingThreshold(uint256 newThreshold) external onlyOwner {
        require(newThreshold > 0 && newThreshold <= 100, "Invalid threshold");
        passingThreshold = newThreshold;
    }
    
    /**
     * @dev Get total number of proposals
     * @return uint256 Total proposal count
     */
    function getTotalProposals() external view returns (uint256) {
        return proposalCounter;
    }
    
    /**
     * @dev Receive function to accept ETH deposits
     */
    receive() external payable {
        treasuryBalance += msg.value;
        emit FundsDeposited(msg.sender, msg.value);
    }
}