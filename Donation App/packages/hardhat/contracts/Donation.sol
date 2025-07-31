// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title DonationApp
 * @dev A comprehensive donation platform with campaigns, goals, and transparent tracking
 */
contract DonationApp {
    struct Campaign {
        string title;
        string description;
        address payable beneficiary;
        uint256 goal;
        uint256 raised;
        uint256 deadline;
        bool active;
        bool goalReached;
        uint256 donorCount;
        address creator;
        uint256 createdAt;
    }

    struct Donation {
        address donor;
        uint256 amount;
        uint256 timestamp;
        uint256 campaignId;
        string message;
    }

    // State variables
    mapping(uint256 => Campaign) public campaigns;
    mapping(uint256 => Donation[]) public campaignDonations;
    mapping(address => uint256[]) public userCampaigns;
    mapping(address => uint256[]) public userDonations;
    
    uint256 public nextCampaignId;
    uint256 public totalCampaigns;
    uint256 public totalDonationsAmount;
    uint256 public totalDonationsCount;
    
    // Platform fee (in basis points, 100 = 1%)
    uint256 public platformFee = 250; // 2.5%
    address public platformOwner;
    uint256 public platformBalance;

    // Events
    event CampaignCreated(
        uint256 indexed campaignId,
        address indexed creator,
        address indexed beneficiary,
        string title,
        uint256 goal,
        uint256 deadline
    );
    
    event DonationMade(
        uint256 indexed campaignId,
        address indexed donor,
        uint256 amount,
        string message
    );
    
    event CampaignGoalReached(uint256 indexed campaignId, uint256 totalRaised);
    event CampaignWithdrawn(uint256 indexed campaignId, address indexed beneficiary, uint256 amount);
    event CampaignCancelled(uint256 indexed campaignId, address indexed creator);
    event PlatformFeeUpdated(uint256 newFee);

    // Errors
    error InvalidGoal();
    error InvalidDeadline();
    error CampaignNotActive();
    error CampaignExpired();
    error NoFundsToWithdraw();
    error UnauthorizedAccess();
    error TransferFailed();
    error InvalidFee();

    // Modifiers
    modifier onlyPlatformOwner() {
        require(msg.sender == platformOwner, "Only platform owner");
        _;
    }

    modifier campaignExists(uint256 _campaignId) {
        require(_campaignId < nextCampaignId, "Campaign does not exist");
        _;
    }

    modifier onlyCampaignCreator(uint256 _campaignId) {
        require(campaigns[_campaignId].creator == msg.sender, "Only campaign creator");
        _;
    }

    constructor() {
        platformOwner = msg.sender;
    }

    /**
     * @dev Create a new donation campaign
     * @param _title Campaign title
     * @param _description Campaign description
     * @param _beneficiary Address that will receive the donations
     * @param _goal Funding goal in wei
     * @param _durationInDays Duration of campaign in days
     */
    function createCampaign(
        string memory _title,
        string memory _description,
        address payable _beneficiary,
        uint256 _goal,
        uint256 _durationInDays
    ) external returns (uint256 campaignId) {
        if (_goal == 0) revert InvalidGoal();
        if (_durationInDays == 0) revert InvalidDeadline();
        require(_beneficiary != address(0), "Invalid beneficiary address");
        require(bytes(_title).length > 0, "Title cannot be empty");

        uint256 deadline = block.timestamp + (_durationInDays * 1 days);
        
        campaignId = nextCampaignId++;
        
        campaigns[campaignId] = Campaign({
            title: _title,
            description: _description,
            beneficiary: _beneficiary,
            goal: _goal,
            raised: 0,
            deadline: deadline,
            active: true,
            goalReached: false,
            donorCount: 0,
            creator: msg.sender,
            createdAt: block.timestamp
        });

        userCampaigns[msg.sender].push(campaignId);
        totalCampaigns++;

        emit CampaignCreated(campaignId, msg.sender, _beneficiary, _title, _goal, deadline);
    }

    /**
     * @dev Donate to a campaign
     * @param _campaignId ID of the campaign to donate to
     * @param _message Optional message from donor
     */
    function donate(uint256 _campaignId, string memory _message) 
        external 
        payable 
        campaignExists(_campaignId) 
    {
        require(msg.value > 0, "Donation must be greater than 0");
        
        Campaign storage campaign = campaigns[_campaignId];
        
        if (!campaign.active) revert CampaignNotActive();
        if (block.timestamp > campaign.deadline) revert CampaignExpired();

        // Calculate platform fee
        uint256 fee = (msg.value * platformFee) / 10000;
        uint256 donationAmount = msg.value - fee;

        // Update campaign
        campaign.raised += donationAmount;
        campaign.donorCount++;
        
        // Check if goal is reached
        if (!campaign.goalReached && campaign.raised >= campaign.goal) {
            campaign.goalReached = true;
            emit CampaignGoalReached(_campaignId, campaign.raised);
        }

        // Record donation
        Donation memory newDonation = Donation({
            donor: msg.sender,
            amount: donationAmount,
            timestamp: block.timestamp,
            campaignId: _campaignId,
            message: _message
        });

        campaignDonations[_campaignId].push(newDonation);
        userDonations[msg.sender].push(_campaignId);

        // Update totals
        totalDonationsAmount += donationAmount;
        totalDonationsCount++;
        platformBalance += fee;

        emit DonationMade(_campaignId, msg.sender, donationAmount, _message);
    }

    /**
     * @dev Withdraw funds from campaign (only beneficiary)
     * @param _campaignId ID of the campaign
     */
    function withdrawFunds(uint256 _campaignId) 
        external 
        campaignExists(_campaignId) 
    {
        Campaign storage campaign = campaigns[_campaignId];
        
        require(msg.sender == campaign.beneficiary, "Only beneficiary can withdraw");
        if (campaign.raised == 0) revert NoFundsToWithdraw();

        uint256 amount = campaign.raised;
        campaign.raised = 0;
        campaign.active = false;

        (bool success, ) = campaign.beneficiary.call{value: amount}("");
        if (!success) revert TransferFailed();

        emit CampaignWithdrawn(_campaignId, campaign.beneficiary, amount);
    }

    /**
     * @dev Cancel campaign (only creator, only if no donations)
     * @param _campaignId ID of the campaign
     */
    function cancelCampaign(uint256 _campaignId) 
        external 
        campaignExists(_campaignId)
        onlyCampaignCreator(_campaignId)
    {
        Campaign storage campaign = campaigns[_campaignId];
        require(campaign.raised == 0, "Cannot cancel campaign with donations");
        
        campaign.active = false;
        
        emit CampaignCancelled(_campaignId, msg.sender);
    }

    /**
     * @dev Get campaign details
     */
    function getCampaign(uint256 _campaignId) 
        external 
        view 
        campaignExists(_campaignId)
        returns (
            string memory title,
            string memory description,
            address beneficiary,
            uint256 goal,
            uint256 raised,
            uint256 deadline,
            bool active,
            bool goalReached,
            uint256 donorCount,
            address creator,
            uint256 createdAt
        ) 
    {
        Campaign memory campaign = campaigns[_campaignId];
        return (
            campaign.title,
            campaign.description,
            campaign.beneficiary,
            campaign.goal,
            campaign.raised,
            campaign.deadline,
            campaign.active,
            campaign.goalReached,
            campaign.donorCount,
            campaign.creator,
            campaign.createdAt
        );
    }

    /**
     * @dev Get campaign progress percentage
     * @param _campaignId ID of the campaign
     * @return percentage Progress as percentage (0-100+)
     */
    function getCampaignProgress(uint256 _campaignId) 
        external 
        view 
        campaignExists(_campaignId)
        returns (uint256 percentage) 
    {
        Campaign memory campaign = campaigns[_campaignId];
        if (campaign.goal == 0) return 0;
        return (campaign.raised * 100) / campaign.goal;
    }

    /**
     * @dev Get donations for a campaign
     * @param _campaignId ID of the campaign
     * @return donations Array of donations
     */
    function getCampaignDonations(uint256 _campaignId) 
        external 
        view 
        campaignExists(_campaignId)
        returns (Donation[] memory donations) 
    {
        return campaignDonations[_campaignId];
    }

    /**
     * @dev Get campaigns created by a user
     * @param _user Address of the user
     * @return campaignIds Array of campaign IDs
     */
    function getUserCampaigns(address _user) 
        external 
        view 
        returns (uint256[] memory campaignIds) 
    {
        return userCampaigns[_user];
    }

    /**
     * @dev Get campaigns a user has donated to
     * @param _user Address of the user
     * @return campaignIds Array of campaign IDs
     */
    function getUserDonations(address _user) 
        external 
        view 
        returns (uint256[] memory campaignIds) 
    {
        return userDonations[_user];
    }

    /**
     * @dev Get active campaigns (view function for frontend)
     * @param _start Start index
     * @param _limit Number of campaigns to return
     */
    function getActiveCampaigns(uint256 _start, uint256 _limit) 
        external 
        view 
        returns (uint256[] memory activeCampaigns) 
    {
        uint256[] memory temp = new uint256[](nextCampaignId);
        uint256 count = 0;
        
        for (uint256 i = _start; i < nextCampaignId && count < _limit; i++) {
            if (campaigns[i].active && block.timestamp <= campaigns[i].deadline) {
                temp[count] = i;
                count++;
            }
        }
        
        // Resize array
        activeCampaigns = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            activeCampaigns[i] = temp[i];
        }
    }

    /**
     * @dev Check if campaign deadline has passed
     * @param _campaignId ID of the campaign
     */
    function isCampaignExpired(uint256 _campaignId) 
        external 
        view 
        campaignExists(_campaignId)
        returns (bool) 
    {
        return block.timestamp > campaigns[_campaignId].deadline;
    }

    /**
     * @dev Get time remaining for campaign
     * @param _campaignId ID of the campaign
     * @return timeLeft Seconds remaining, 0 if expired
     */
    function getTimeLeft(uint256 _campaignId) 
        external 
        view 
        campaignExists(_campaignId)
        returns (uint256 timeLeft) 
    {
        uint256 deadline = campaigns[_campaignId].deadline;
        if (block.timestamp >= deadline) {
            return 0;
        }
        return deadline - block.timestamp;
    }

    /**
     * @dev Update platform fee (only platform owner)
     * @param _newFee New fee in basis points (100 = 1%)
     */
    function updatePlatformFee(uint256 _newFee) external onlyPlatformOwner {
        if (_newFee > 1000) revert InvalidFee(); // Max 10%
        platformFee = _newFee;
        emit PlatformFeeUpdated(_newFee);
    }

    /**
     * @dev Withdraw platform fees (only platform owner)
     */
    function withdrawPlatformFees() external onlyPlatformOwner {
        uint256 amount = platformBalance;
        platformBalance = 0;
        
        (bool success, ) = payable(platformOwner).call{value: amount}("");
        if (!success) revert TransferFailed();
    }

    /**
     * @dev Transfer platform ownership
     * @param _newOwner New platform owner address
     */
    function transferOwnership(address _newOwner) external onlyPlatformOwner {
        require(_newOwner != address(0), "Invalid address");
        platformOwner = _newOwner;
    }

    /**
     * @dev Get platform statistics
     */
    function getPlatformStats() external view returns (
        uint256 _totalCampaigns,
        uint256 _totalDonationsAmount,
        uint256 _totalDonationsCount,
        uint256 _platformFee,
        uint256 _platformBalance
    ) {
        return (
            totalCampaigns,
            totalDonationsAmount,
            totalDonationsCount,
            platformFee,
            platformBalance
        );
    }

    /**
     * @dev Emergency pause function (only platform owner)
     */
    function emergencyPause() external onlyPlatformOwner {
        // In a production contract, you'd implement a proper pause mechanism
        // This is a simplified version
        selfdestruct(payable(platformOwner));
    }

    // Prevent accidental ETH sends
    receive() external payable {
        revert("Use donate() function to make donations");
    }

    fallback() external payable {
        revert("Function not found. Use donate() to make donations");
    }
}