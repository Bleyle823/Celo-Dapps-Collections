"use client";

import { useState } from "react";
import { notification } from "~~/utils/scaffold-eth";

export const CreateEscrow = () => {
  const [contractAddress, setContractAddress] = useState<string>("");

  const handleCopyAddress = () => {
    // Copy the deployed contract address to clipboard
    navigator.clipboard.writeText("0xf76C38A96b4Cf140099BF810556B235E10D62585");
    notification.success("Contract address copied to clipboard!");
  };

  return (
    <div className="space-y-4">
      <div className="alert alert-info">
        <span>
          <strong>Info:</strong> To create a new escrow contract, you need to deploy it using the Hardhat deployment script.
          <br />
          Run <code className="bg-base-300 px-2 py-1 rounded">yarn deploy</code> in the hardhat package to deploy a new contract.
        </span>
      </div>

      <div>
        <label className="label">
          <span className="label-text">Currently Deployed Contract Address</span>
        </label>
        <div className="flex gap-2">
          <input
            type="text"
            value="0xf76C38A96b4Cf140099BF810556B235E10D62585"
            className="input input-bordered flex-1"
            readOnly
          />
          <button
            className="btn btn-secondary"
            onClick={handleCopyAddress}
          >
            Copy
          </button>
        </div>
        <div className="text-sm text-base-content/70 mt-1">
          This is the address of the currently deployed SimpleEscrow contract on Celo network.
        </div>
      </div>

      <div className="alert alert-warning">
        <span>
          <strong>Note:</strong> The deployed contract uses the deployer account as both seller and arbiter for demo purposes.
          <br />
          In a real scenario, you would want to deploy contracts with different addresses for each role.
        </span>
      </div>
    </div>
  );
}; 