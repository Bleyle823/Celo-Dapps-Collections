"use client";

import { useState } from "react";
import { Address } from "~~/components/scaffold-eth";
import { useScaffoldContractWrite } from "~~/hooks/scaffold-eth";
import { notification } from "~~/utils/scaffold-eth";

type ContractDetails = {
  _buyer: string;
  _seller: string;
  _arbiter: string;
  _amount: bigint;
  _state: number;
  _disputed: boolean;
};

type EscrowActionsProps = {
  escrowAddress: string;
  contractDetails: ContractDetails;
  connectedAddress: string;
};

export const EscrowActions = ({ escrowAddress, contractDetails, connectedAddress }: EscrowActionsProps) => {
  const { _buyer, _seller, _arbiter, _state, _disputed } = contractDetails;
  const [depositAmount, setDepositAmount] = useState<string>("");
  const [disputeWinner, setDisputeWinner] = useState<string>("");

  const isBuyer = connectedAddress.toLowerCase() === _buyer.toLowerCase();
  const isSeller = connectedAddress.toLowerCase() === _seller.toLowerCase();
  const isArbiter = connectedAddress.toLowerCase() === _arbiter.toLowerCase();

  // Contract write functions
  const { writeAsync: depositFunds, isPending: isDepositing } = useScaffoldContractWrite({
    contractName: "SimpleEscrow",
    functionName: "depositFunds",
    contractAddress: escrowAddress,
    value: depositAmount ? BigInt(depositAmount) : undefined,
  });

  const { writeAsync: confirmDelivery, isPending: isConfirming } = useScaffoldContractWrite({
    contractName: "SimpleEscrow",
    functionName: "confirmDelivery",
    contractAddress: escrowAddress,
  });

  const { writeAsync: requestRelease, isPending: isRequesting } = useScaffoldContractWrite({
    contractName: "SimpleEscrow",
    functionName: "requestRelease",
    contractAddress: escrowAddress,
  });

  const { writeAsync: raiseDispute, isPending: isRaisingDispute } = useScaffoldContractWrite({
    contractName: "SimpleEscrow",
    functionName: "raiseDispute",
    contractAddress: escrowAddress,
  });

  const { writeAsync: resolveDispute, isPending: isResolving } = useScaffoldContractWrite({
    contractName: "SimpleEscrow",
    functionName: "resolveDispute",
    contractAddress: escrowAddress,
    args: [disputeWinner as `0x${string}`],
  });

  const handleDeposit = async () => {
    if (!depositAmount || BigInt(depositAmount) <= 0) {
      notification.error("Please enter a valid amount");
      return;
    }
    try {
      await depositFunds();
      setDepositAmount("");
      notification.success("Funds deposited successfully!");
    } catch (error) {
      notification.error("Failed to deposit funds");
    }
  };

  const handleConfirmDelivery = async () => {
    try {
      await confirmDelivery();
      notification.success("Delivery confirmed! Funds released to seller.");
    } catch (error) {
      notification.error("Failed to confirm delivery");
    }
  };

  const handleRequestRelease = async () => {
    try {
      await requestRelease();
      notification.success("Release requested! Buyer will be notified.");
    } catch (error) {
      notification.error("Failed to request release");
    }
  };

  const handleRaiseDispute = async () => {
    try {
      await raiseDispute();
      notification.success("Dispute raised! Arbiter will be notified.");
    } catch (error) {
      notification.error("Failed to raise dispute");
    }
  };

  const handleResolveDispute = async () => {
    if (!disputeWinner || !/^0x[a-fA-F0-9]{40}$/.test(disputeWinner)) {
      notification.error("Please enter a valid winner address");
      return;
    }
    if (disputeWinner.toLowerCase() !== _buyer.toLowerCase() && disputeWinner.toLowerCase() !== _seller.toLowerCase()) {
      notification.error("Winner must be either buyer or seller");
      return;
    }
    try {
      await resolveDispute();
      setDisputeWinner("");
      notification.success("Dispute resolved successfully!");
    } catch (error) {
      notification.error("Failed to resolve dispute");
    }
  };

  return (
    <div className="bg-base-100 rounded-3xl shadow-md shadow-secondary border border-base-300 p-6">
      <h2 className="text-2xl font-bold mb-6">Available Actions</h2>

      <div className="space-y-6">
        {/* Buyer Actions */}
        {isBuyer && _state === 0 && (
          <div className="bg-base-200 rounded-lg p-4">
            <h3 className="text-lg font-semibold mb-3">Buyer Actions - Deposit Funds</h3>
            <div className="flex flex-col sm:flex-row gap-3">
              <input
                type="text"
                placeholder="Amount in wei"
                className="input input-bordered flex-1"
                value={depositAmount}
                onChange={(e) => setDepositAmount(e.target.value)}
              />
              <button
                className="btn btn-primary"
                onClick={handleDeposit}
                disabled={isDepositing || !depositAmount}
              >
                {isDepositing ? "Depositing..." : "Deposit Funds"}
              </button>
            </div>
          </div>
        )}

        {isBuyer && _state === 1 && (
          <div className="bg-base-200 rounded-lg p-4">
            <h3 className="text-lg font-semibold mb-3">Buyer Actions - Confirm Delivery</h3>
            <button
              className="btn btn-success"
              onClick={handleConfirmDelivery}
              disabled={isConfirming}
            >
              {isConfirming ? "Confirming..." : "Confirm Delivery & Release Funds"}
            </button>
          </div>
        )}

        {/* Seller Actions */}
        {isSeller && _state === 1 && (
          <div className="bg-base-200 rounded-lg p-4">
            <h3 className="text-lg font-semibold mb-3">Seller Actions</h3>
            <button
              className="btn btn-info"
              onClick={handleRequestRelease}
              disabled={isRequesting}
            >
              {isRequesting ? "Requesting..." : "Request Release"}
            </button>
          </div>
        )}

        {/* Dispute Actions */}
        {_state === 1 && (isBuyer || isSeller) && (
          <div className="bg-base-200 rounded-lg p-4">
            <h3 className="text-lg font-semibold mb-3">Dispute Actions</h3>
            <button
              className="btn btn-warning"
              onClick={handleRaiseDispute}
              disabled={isRaisingDispute}
            >
              {isRaisingDispute ? "Raising..." : "Raise Dispute"}
            </button>
          </div>
        )}

        {/* Arbiter Actions */}
        {isArbiter && _state === 3 && _disputed && (
          <div className="bg-base-200 rounded-lg p-4">
            <h3 className="text-lg font-semibold mb-3">Arbiter Actions - Resolve Dispute</h3>
            <div className="space-y-3">
              <div>
                <label className="label">
                  <span className="label-text">Winner Address</span>
                </label>
                <input
                  type="text"
                  placeholder="0x..."
                  className="input input-bordered w-full"
                  value={disputeWinner}
                  onChange={(e) => setDisputeWinner(e.target.value)}
                />
                <div className="text-sm text-base-content/70 mt-1">
                  Must be either buyer or seller address
                </div>
              </div>
              <div className="flex gap-2">
                <button
                  className="btn btn-primary"
                  onClick={() => setDisputeWinner(_buyer)}
                >
                  Award to Buyer
                </button>
                <button
                  className="btn btn-secondary"
                  onClick={() => setDisputeWinner(_seller)}
                >
                  Award to Seller
                </button>
              </div>
              <button
                className="btn btn-success w-full"
                onClick={handleResolveDispute}
                disabled={isResolving || !disputeWinner}
              >
                {isResolving ? "Resolving..." : "Resolve Dispute"}
              </button>
            </div>
          </div>
        )}

        {/* No Actions Available */}
        {((_state === 2) || (_state === 0 && !isBuyer) || (_state === 1 && !isBuyer && !isSeller) || (_state === 3 && !isArbiter)) && (
          <div className="bg-base-200 rounded-lg p-4">
            <h3 className="text-lg font-semibold mb-3">No Actions Available</h3>
            <p className="text-base-content/70">
              {_state === 2 
                ? "Contract is complete. No further actions needed."
                : "You don't have permission to perform any actions in the current state."
              }
            </p>
          </div>
        )}
      </div>

      {/* Action Descriptions */}
      <div className="mt-6 p-4 bg-base-300 rounded-lg">
        <h3 className="font-semibold mb-2">Action Descriptions:</h3>
        <ul className="text-sm space-y-1">
          <li><strong>Deposit Funds:</strong> Buyer deposits payment into escrow</li>
          <li><strong>Confirm Delivery:</strong> Buyer confirms receipt and releases funds to seller</li>
          <li><strong>Request Release:</strong> Seller requests buyer to release funds</li>
          <li><strong>Raise Dispute:</strong> Either party can raise a dispute for arbitration</li>
          <li><strong>Resolve Dispute:</strong> Arbiter decides who gets the funds</li>
        </ul>
      </div>
    </div>
  );
}; 