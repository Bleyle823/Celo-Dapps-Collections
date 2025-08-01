"use client";

import { Address, Balance } from "~~/components/scaffold-eth";

type ContractDetails = {
  _buyer: string;
  _seller: string;
  _arbiter: string;
  _amount: bigint;
  _state: number;
  _disputed: boolean;
};

type EscrowContractDetailsProps = {
  contractDetails: ContractDetails;
  contractBalance: bigint | undefined;
  contractAddress: string;
  connectedAddress: string;
};

const getStateString = (state: number): string => {
  switch (state) {
    case 0:
      return "AWAITING_PAYMENT";
    case 1:
      return "AWAITING_DELIVERY";
    case 2:
      return "COMPLETE";
    case 3:
      return "DISPUTED";
    default:
      return "UNKNOWN";
  }
};

const getStateColor = (state: number): string => {
  switch (state) {
    case 0:
      return "text-warning";
    case 1:
      return "text-info";
    case 2:
      return "text-success";
    case 3:
      return "text-error";
    default:
      return "text-neutral";
  }
};

export const EscrowContractDetails = ({ 
  contractDetails, 
  contractBalance, 
  contractAddress, 
  connectedAddress 
}: EscrowContractDetailsProps) => {
  const { _buyer, _seller, _arbiter, _amount, _state, _disputed } = contractDetails;
  
  const isBuyer = connectedAddress.toLowerCase() === _buyer.toLowerCase();
  const isSeller = connectedAddress.toLowerCase() === _seller.toLowerCase();
  const isArbiter = connectedAddress.toLowerCase() === _arbiter.toLowerCase();

  return (
    <div className="bg-base-100 rounded-3xl shadow-md shadow-secondary border border-base-300 p-6 mb-8">
      <h2 className="text-2xl font-bold mb-6">Contract Details</h2>
      
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* Contract Address and Balance */}
        <div className="space-y-4">
          <div>
            <label className="label">
              <span className="label-text font-semibold">Contract Address</span>
            </label>
            <Address address={contractAddress} />
          </div>
          
          <div>
            <label className="label">
              <span className="label-text font-semibold">Contract Balance</span>
            </label>
            <div className="flex items-center gap-2">
              <Balance address={contractAddress} className="px-0 h-1.5 min-h-[0.375rem]" />
            </div>
          </div>
        </div>

        {/* Contract State */}
        <div className="space-y-4">
          <div>
            <label className="label">
              <span className="label-text font-semibold">Current State</span>
            </label>
            <div className={`text-lg font-bold ${getStateColor(_state)}`}>
              {getStateString(_state)}
            </div>
          </div>
          
          <div>
            <label className="label">
              <span className="label-text font-semibold">Escrow Amount</span>
            </label>
            <div className="text-lg">
              {_amount ? `${_amount.toString()} wei` : "No funds deposited"}
            </div>
          </div>
          
          {_disputed && (
            <div className="alert alert-error">
              <span>⚠️ Dispute has been raised</span>
            </div>
          )}
        </div>
      </div>

      {/* Participants */}
      <div className="mt-8">
        <h3 className="text-xl font-bold mb-4">Participants</h3>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div className="bg-base-200 rounded-lg p-4">
            <div className="font-semibold mb-2">Buyer</div>
            <Address address={_buyer} />
            {isBuyer && <div className="badge badge-primary mt-2">You</div>}
          </div>
          
          <div className="bg-base-200 rounded-lg p-4">
            <div className="font-semibold mb-2">Seller</div>
            <Address address={_seller} />
            {isSeller && <div className="badge badge-secondary mt-2">You</div>}
          </div>
          
          <div className="bg-base-200 rounded-lg p-4">
            <div className="font-semibold mb-2">Arbiter</div>
            <Address address={_arbiter} />
            {isArbiter && <div className="badge badge-accent mt-2">You</div>}
          </div>
        </div>
      </div>

      {/* Your Role */}
      <div className="mt-6">
        <div className="alert alert-info">
          <span>
            <strong>Your Role:</strong>{" "}
            {isBuyer ? "Buyer" : isSeller ? "Seller" : isArbiter ? "Arbiter" : "Observer"}
          </span>
        </div>
      </div>
    </div>
  );
}; 