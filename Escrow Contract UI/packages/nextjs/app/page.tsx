"use client";

import Link from "next/link";
import type { NextPage } from "next";
import { useState } from "react";
import { useAccount } from "wagmi";
import { BugAntIcon, MagnifyingGlassIcon, ShieldCheckIcon } from "@heroicons/react/24/outline";
import { Address, Balance } from "~~/components/scaffold-eth";
import { useScaffoldReadContract } from "~~/hooks/scaffold-eth";
import { notification } from "~~/utils/scaffold-eth";

const Home: NextPage = () => {
  const { address: connectedAddress } = useAccount();
  const [escrowAddress, setEscrowAddress] = useState<string>("0xf76C38A96b4Cf140099BF810556B235E10D62585");
  const [isValidAddress, setIsValidAddress] = useState<boolean>(true);

  // Read contract details
  const { data: contractDetails } = useScaffoldReadContract({
    contractName: "SimpleEscrow",
    functionName: "getContractDetails",
    watch: true,
  });

  // Read contract balance
  const { data: contractBalance } = useScaffoldReadContract({
    contractName: "SimpleEscrow",
    functionName: "getBalance",
    watch: true,
  });

  const handleAddressChange = (address: string) => {
    setEscrowAddress(address);
    const isValid = /^0x[a-fA-F0-9]{40}$/.test(address);
    setIsValidAddress(isValid);
  };

  const copyAddress = () => {
    navigator.clipboard.writeText(escrowAddress);
    notification.success("Contract address copied to clipboard!");
  };

  const getStateString = (state: number): string => {
    switch (state) {
      case 0: return "AWAITING_PAYMENT";
      case 1: return "AWAITING_DELIVERY";
      case 2: return "COMPLETE";
      case 3: return "DISPUTED";
      default: return "UNKNOWN";
    }
  };

  const getStateColor = (state: number): string => {
    switch (state) {
      case 0: return "text-warning";
      case 1: return "text-info";
      case 2: return "text-success";
      case 3: return "text-error";
      default: return "text-neutral";
    }
  };

  return (
    <>
      <div className="flex items-center flex-col grow pt-10">
        <div className="px-5">
          <h1 className="text-center">
            <span className="block text-2xl mb-2">Welcome to</span>
            <span className="block text-4xl font-bold">Escrow Contract UI</span>
          </h1>
          <div className="flex justify-center items-center space-x-2 flex-col">
            <p className="my-2 font-medium">Connected Address:</p>
            <Address address={connectedAddress} />
          </div>
          <p className="text-center text-lg mt-4">
            Interact with the SimpleEscrow smart contract on Celo network
          </p>
        </div>

        {/* Escrow Contract Interface */}
        <div className="w-full max-w-6xl px-6 lg:px-10 mt-8">
          <div className="bg-base-100 rounded-3xl shadow-md shadow-secondary border border-base-300 p-6 mb-8">
            <h2 className="text-2xl font-bold mb-6">Escrow Contract Interface</h2>
            
            {/* Contract Address Input */}
            <div className="mb-6">
              <label className="label">
                <span className="label-text font-semibold">Contract Address</span>
              </label>
              <div className="flex gap-2">
                <input
                  type="text"
                  placeholder="0x..."
                  className={`input input-bordered flex-1 ${isValidAddress ? 'input-success' : 'input-error'}`}
                  value={escrowAddress}
                  onChange={(e) => handleAddressChange(e.target.value)}
                />
                <button className="btn btn-secondary" onClick={copyAddress}>
                  Copy
                </button>
              </div>
              {!isValidAddress && (
                <label className="label">
                  <span className="label-text-alt text-error">Invalid address format</span>
                </label>
              )}
            </div>

            {/* Contract Details */}
            {isValidAddress && contractDetails && (
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
                <div className="space-y-4">
                  <div>
                    <label className="label">
                      <span className="label-text font-semibold">Contract Balance</span>
                    </label>
                    <div className="flex items-center gap-2">
                      <Balance address={escrowAddress as `0x${string}`} className="px-0 h-1.5 min-h-[0.375rem]" />
                    </div>
                  </div>
                  
                                     <div>
                     <label className="label">
                       <span className="label-text font-semibold">Current State</span>
                     </label>
                     <div className={`text-lg font-bold ${getStateColor(contractDetails[4])}`}>
                       {getStateString(contractDetails[4])}
                     </div>
                   </div>
                   
                   <div>
                     <label className="label">
                       <span className="label-text font-semibold">Escrow Amount</span>
                     </label>
                     <div className="text-lg">
                       {contractDetails[3] ? `${contractDetails[3].toString()} wei` : "No funds deposited"}
                     </div>
                   </div>
                </div>

                                 <div className="space-y-4">
                   <div>
                     <label className="label">
                       <span className="label-text font-semibold">Buyer</span>
                     </label>
                     <Address address={contractDetails[0]} />
                   </div>
                   
                   <div>
                     <label className="label">
                       <span className="label-text font-semibold">Seller</span>
                     </label>
                     <Address address={contractDetails[1]} />
                   </div>
                   
                   <div>
                     <label className="label">
                       <span className="label-text font-semibold">Arbiter</span>
                     </label>
                     <Address address={contractDetails[2]} />
                   </div>
                 </div>
              </div>
            )}

            {/* User Role and Quick Actions */}
            {isValidAddress && contractDetails && connectedAddress && (
              <div className="mb-6">
                <div className="alert alert-info mb-4">
                  <span>
                    <strong>Your Role:</strong>{" "}
                    {connectedAddress.toLowerCase() === contractDetails[0].toLowerCase() 
                      ? "Buyer" 
                      : connectedAddress.toLowerCase() === contractDetails[1].toLowerCase()
                      ? "Seller"
                      : connectedAddress.toLowerCase() === contractDetails[2].toLowerCase()
                      ? "Arbiter"
                      : "Observer"
                    }
                  </span>
                </div>

                {/* Available Actions Based on Role and State */}
                <div className="bg-base-200 rounded-lg p-4 mb-4">
                  <h3 className="font-semibold mb-2">Available Actions:</h3>
                  <div className="text-sm space-y-1">
                    {connectedAddress.toLowerCase() === contractDetails[0].toLowerCase() && contractDetails[4] === 0 && (
                      <div className="text-warning">• You can deposit funds as the buyer</div>
                    )}
                    {connectedAddress.toLowerCase() === contractDetails[0].toLowerCase() && contractDetails[4] === 1 && (
                      <div className="text-info">• You can confirm delivery and release funds</div>
                    )}
                    {connectedAddress.toLowerCase() === contractDetails[1].toLowerCase() && contractDetails[4] === 1 && (
                      <div className="text-info">• You can request release of funds</div>
                    )}
                    {(connectedAddress.toLowerCase() === contractDetails[0].toLowerCase() || 
                      connectedAddress.toLowerCase() === contractDetails[1].toLowerCase()) && contractDetails[4] === 1 && (
                      <div className="text-warning">• You can raise a dispute if needed</div>
                    )}
                    {connectedAddress.toLowerCase() === contractDetails[2].toLowerCase() && contractDetails[4] === 3 && (
                      <div className="text-error">• You can resolve the dispute as arbiter</div>
                    )}
                    {contractDetails[4] === 2 && (
                      <div className="text-success">• Contract is complete</div>
                    )}
                  </div>
                </div>
                
                <div className="flex flex-wrap gap-4">
                  <Link href="/debug" className="btn btn-primary">
                    <BugAntIcon className="h-4 w-4 mr-2" />
                    Debug Contracts
                  </Link>
                  <Link href="/escrow" className="btn btn-secondary">
                    <ShieldCheckIcon className="h-4 w-4 mr-2" />
                    Full Escrow Interface
                  </Link>
                  <Link href="/blockexplorer" className="btn btn-accent">
                    <MagnifyingGlassIcon className="h-4 w-4 mr-2" />
                    Block Explorer
                  </Link>
                </div>
              </div>
            )}

            {/* Default Actions when not connected or no contract details */}
            {(!connectedAddress || !contractDetails) && (
              <div className="flex flex-wrap gap-4">
                <Link href="/debug" className="btn btn-primary">
                  <BugAntIcon className="h-4 w-4 mr-2" />
                  Debug Contracts
                </Link>
                <Link href="/escrow" className="btn btn-secondary">
                  <ShieldCheckIcon className="h-4 w-4 mr-2" />
                  Full Escrow Interface
                </Link>
                <Link href="/blockexplorer" className="btn btn-accent">
                  <MagnifyingGlassIcon className="h-4 w-4 mr-2" />
                  Block Explorer
                </Link>
              </div>
            )}
          </div>
        </div>

        {/* Navigation Cards */}
        <div className="grow bg-base-300 w-full mt-8 px-8 py-12">
          <div className="flex justify-center items-center gap-12 flex-col md:flex-row">
            <div className="flex flex-col bg-base-100 px-10 py-10 text-center items-center max-w-xs rounded-3xl">
              <BugAntIcon className="h-8 w-8 fill-secondary" />
              <p>
                Tinker with your smart contract using the{" "}
                <Link href="/debug" passHref className="link">
                  Debug Contracts
                </Link>{" "}
                tab.
              </p>
            </div>
            <div className="flex flex-col bg-base-100 px-10 py-10 text-center items-center max-w-xs rounded-3xl">
              <MagnifyingGlassIcon className="h-8 w-8 fill-secondary" />
              <p>
                Explore your local transactions with the{" "}
                <Link href="/blockexplorer" passHref className="link">
                  Block Explorer
                </Link>{" "}
                tab.
              </p>
            </div>
            <div className="flex flex-col bg-base-100 px-10 py-10 text-center items-center max-w-xs rounded-3xl">
              <ShieldCheckIcon className="h-8 w-8 fill-secondary" />
              <p>
                Manage escrow transactions with the{" "}
                <Link href="/escrow" passHref className="link">
                  Escrow Interface
                </Link>{" "}
                tab.
              </p>
            </div>
          </div>
        </div>
      </div>
    </>
  );
};

export default Home;
