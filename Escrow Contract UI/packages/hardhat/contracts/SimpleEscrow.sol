// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SimpleEscrow {
    address public buyer;
    address public seller;
    address public arbiter;
    uint256 public amount;
    bool public fundsDeposited;
    bool public fundsReleased;
    bool public disputed;
    
    enum State { AWAITING_PAYMENT, AWAITING_DELIVERY, COMPLETE, DISPUTED }
    State public currentState;
    
    event FundsDeposited(uint256 amount);
    event FundsReleased(address to, uint256 amount);
    event DisputeRaised();
    event DisputeResolved(address winner);
    
    modifier onlyBuyer() {
        require(msg.sender == buyer, "Only buyer can call this");
        _;
    }
    
    modifier onlySeller() {
        require(msg.sender == seller, "Only seller can call this");
        _;
    }
    
    modifier onlyArbiter() {
        require(msg.sender == arbiter, "Only arbiter can call this");
        _;
    }
    
    modifier inState(State _state) {
        require(currentState == _state, "Invalid state for this action");
        _;
    }
    
    constructor(address _seller, address _arbiter) {
        buyer = msg.sender;
        seller = _seller;
        arbiter = _arbiter;
        currentState = State.AWAITING_PAYMENT;
    }
    
    // Buyer deposits funds into escrow
    function depositFunds() external payable onlyBuyer inState(State.AWAITING_PAYMENT) {
        require(msg.value > 0, "Must deposit some funds");
        amount = msg.value;
        fundsDeposited = true;
        currentState = State.AWAITING_DELIVERY;
        emit FundsDeposited(msg.value);
    }
    
    // Buyer confirms delivery and releases funds to seller
    function confirmDelivery() external onlyBuyer inState(State.AWAITING_DELIVERY) {
        _releaseFunds(seller);
    }
    
    // Seller can request release (buyer still needs to confirm)
    function requestRelease() external onlySeller inState(State.AWAITING_DELIVERY) {
        // This could trigger a notification to buyer
        // For now, it's just a placeholder for future functionality
    }
    
    // Either party can raise a dispute
    function raiseDispute() external inState(State.AWAITING_DELIVERY) {
        require(msg.sender == buyer || msg.sender == seller, "Only buyer or seller can raise dispute");
        disputed = true;
        currentState = State.DISPUTED;
        emit DisputeRaised();
    }
    
    // Arbiter resolves dispute by awarding funds to either buyer or seller
    function resolveDispute(address winner) external onlyArbiter inState(State.DISPUTED) {
        require(winner == buyer || winner == seller, "Winner must be buyer or seller");
        _releaseFunds(winner);
        emit DisputeResolved(winner);
    }
    
    // Internal function to release funds
    function _releaseFunds(address recipient) internal {
        require(fundsDeposited && !fundsReleased, "Funds not available for release");
        fundsReleased = true;
        currentState = State.COMPLETE;
        
        uint256 payout = amount;
        amount = 0;
        
        payable(recipient).transfer(payout);
        emit FundsReleased(recipient, payout);
    }
    
    // Get contract balance
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    // Get contract details
    function getContractDetails() external view returns (
        address _buyer,
        address _seller, 
        address _arbiter,
        uint256 _amount,
        State _state,
        bool _disputed
    ) {
        return (buyer, seller, arbiter, amount, currentState, disputed);
    }
}