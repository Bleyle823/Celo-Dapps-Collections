"use client";

import { useAccount } from "wagmi";
import { Address } from "~~/components/scaffold-eth";
import { CreateEscrow } from "./CreateEscrow";

export const EscrowInterface = () => {
  const { address: connectedAddress } = useAccount();

  if (!connectedAddress) {
    return (
      <div className="flex flex-col gap-y-6 lg:gap-y-8 py-8 lg:py-12 justify-center items-center">
        <div className="text-center">
          <h2 className="text-2xl font-bold mb-4">Connect Your Wallet</h2>
          <p className="text-lg">Please connect your wallet to use the Escrow Interface.</p>
        </div>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-y-6 lg:gap-y-8 py-8 lg:py-12 justify-center items-center">
      <div className="w-full max-w-7xl px-6 lg:px-10">
        {/* Header */}
        <div className="text-center mb-8">
          <h1 className="text-3xl font-bold mb-4">Escrow Contract Interface</h1>
          <div className="flex justify-center items-center space-x-2">
            <p className="font-medium">Connected Address:</p>
            <Address address={connectedAddress} />
          </div>
        </div>

        {/* Contract Information Section */}
        <div className="bg-base-100 rounded-3xl shadow-md shadow-secondary border border-base-300 p-6 mb-8">
          <h2 className="text-2xl font-bold mb-4">Contract Information</h2>
          <CreateEscrow />
        </div>

        {/* Instructions */}
        <div className="bg-base-100 rounded-3xl shadow-md shadow-secondary border border-base-300 p-6 mb-8">
          <h2 className="text-2xl font-bold mb-4">How to Use</h2>
          <div className="space-y-4">
            <div className="alert alert-info">
              <span>
                <strong>Step 1:</strong> Copy the deployed contract address above
              </span>
            </div>
            <div className="alert alert-info">
              <span>
                <strong>Step 2:</strong> Go to the{" "}
                <a href="/debug" className="link link-primary">
                  Debug Contracts
                </a>{" "}
                page to interact with the escrow contract
              </span>
            </div>
            <div className="alert alert-info">
              <span>
                <strong>Step 3:</strong> Use the contract functions to manage your escrow transactions
              </span>
            </div>
          </div>
        </div>

        {/* Contract Functions Overview */}
        <div className="bg-base-100 rounded-3xl shadow-md shadow-secondary border border-base-300 p-6">
          <h2 className="text-2xl font-bold mb-4">Available Functions</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="bg-base-200 rounded-lg p-4">
              <h3 className="font-semibold mb-2">Buyer Functions</h3>
              <ul className="text-sm space-y-1">
                <li><strong>depositFunds:</strong> Deposit payment into escrow</li>
                <li><strong>confirmDelivery:</strong> Confirm receipt and release funds</li>
              </ul>
            </div>
            <div className="bg-base-200 rounded-lg p-4">
              <h3 className="font-semibold mb-2">Seller Functions</h3>
              <ul className="text-sm space-y-1">
                <li><strong>requestRelease:</strong> Request buyer to release funds</li>
              </ul>
            </div>
            <div className="bg-base-200 rounded-lg p-4">
              <h3 className="font-semibold mb-2">Dispute Functions</h3>
              <ul className="text-sm space-y-1">
                <li><strong>raiseDispute:</strong> Raise a dispute (buyer/seller)</li>
                <li><strong>resolveDispute:</strong> Resolve dispute (arbiter only)</li>
              </ul>
            </div>
            <div className="bg-base-200 rounded-lg p-4">
              <h3 className="font-semibold mb-2">View Functions</h3>
              <ul className="text-sm space-y-1">
                <li><strong>getContractDetails:</strong> Get all contract details</li>
                <li><strong>getBalance:</strong> Get contract balance</li>
              </ul>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}; 