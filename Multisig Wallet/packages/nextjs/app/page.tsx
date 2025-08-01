"use client";

import { useState, useEffect } from "react";
import type { NextPage } from "next";
import { useAccount } from "wagmi";
import { 
  BugAntIcon, 
  MagnifyingGlassIcon,
  PlusIcon,
  CheckIcon,
  PlayIcon,
  XMarkIcon,
  CurrencyDollarIcon,
  UserGroupIcon,
  DocumentTextIcon
} from "@heroicons/react/24/outline";
import { Address } from "~~/components/scaffold-eth";
import { useScaffoldReadContract, useScaffoldWriteContract } from "~~/hooks/scaffold-eth";
import { notification } from "~~/utils/scaffold-eth";
import { AddressInput, EtherInput } from "~~/components/scaffold-eth";

const Home: NextPage = () => {
  const { address: connectedAddress } = useAccount();
  
  // State for form inputs
  const [recipientAddress, setRecipientAddress] = useState("");
  const [transactionValue, setTransactionValue] = useState("");
  const [transactionData, setTransactionData] = useState("");

  const [selectedTxIndex, setSelectedTxIndex] = useState<number | null>(null);

  // Read contract data
  const { data: owners } = useScaffoldReadContract({
    contractName: "SimpleMultisig",
    functionName: "getOwners",
  });

  const { data: numConfirmationsRequired } = useScaffoldReadContract({
    contractName: "SimpleMultisig",
    functionName: "numConfirmationsRequired",
  });

  const { data: transactionCount } = useScaffoldReadContract({
    contractName: "SimpleMultisig",
    functionName: "getTransactionCount",
  });

  const { data: contractBalance } = useScaffoldReadContract({
    contractName: "SimpleMultisig",
    functionName: "getBalance",
  });

  const { data: isOwner } = useScaffoldReadContract({
    contractName: "SimpleMultisig",
    functionName: "isOwner",
    args: [connectedAddress],
  });

  // Write contract functions
  const { writeContractAsync: submitTransaction } = useScaffoldWriteContract("SimpleMultisig");
  const { writeContractAsync: confirmTransaction } = useScaffoldWriteContract("SimpleMultisig");
  const { writeContractAsync: executeTransaction } = useScaffoldWriteContract("SimpleMultisig");
  const { writeContractAsync: revokeConfirmation } = useScaffoldWriteContract("SimpleMultisig");

  // State for transactions
  const [transactions, setTransactions] = useState<any[]>([]);
  const [confirmations, setConfirmations] = useState<{[key: number]: boolean}>({});

  // Load transactions - simplified approach
  useEffect(() => {
    const loadTransactions = async () => {
      if (!transactionCount || !connectedAddress) return;
      
      const txArray = [];
      const confirmationsMap: {[key: number]: boolean} = {};
      
      // For now, we'll show a simplified view without individual transaction loading
      // This can be enhanced later with proper transaction fetching
      setTransactions([]);
      setConfirmations({});
    };

    loadTransactions();
  }, [transactionCount, connectedAddress]);

  const handleSubmitTransaction = async () => {
    if (!recipientAddress || !transactionValue) {
      notification.error("Please fill in all required fields");
      return;
    }

    try {
      await submitTransaction({
        functionName: "submitTransaction",
        args: [recipientAddress, BigInt(transactionValue), (transactionData || "0x") as `0x${string}`],
      });
      
      // Clear form
      setRecipientAddress("");
      setTransactionValue("");
      setTransactionData("");
      
      notification.success("Transaction submitted successfully!");
    } catch (error) {
      notification.error("Failed to submit transaction");
      console.error(error);
    }
  };

  const handleConfirmTransaction = async (txIndex: number) => {
    try {
      await confirmTransaction({
        functionName: "confirmTransaction",
        args: [BigInt(txIndex)],
      });
      notification.success("Transaction confirmed successfully!");
    } catch (error) {
      notification.error("Failed to confirm transaction");
      console.error(error);
    }
  };

  const handleExecuteTransaction = async (txIndex: number) => {
    try {
      await executeTransaction({
        functionName: "executeTransaction",
        args: [BigInt(txIndex)],
      });
      notification.success("Transaction executed successfully!");
    } catch (error) {
      notification.error("Failed to execute transaction");
      console.error(error);
    }
  };

  const handleRevokeConfirmation = async (txIndex: number) => {
    try {
      await revokeConfirmation({
        functionName: "revokeConfirmation",
        args: [BigInt(txIndex)],
      });
      notification.success("Confirmation revoked successfully!");
    } catch (error) {
      notification.error("Failed to revoke confirmation");
      console.error(error);
    }
  };

  const formatEther = (wei: bigint) => {
    return Number(wei) / 1e18;
  };

  return (
    <>
      <div className="flex items-center flex-col grow pt-10">
        <div className="px-5 w-full max-w-6xl">
          <h1 className="text-center mb-8">
            <span className="block text-2xl mb-2">Welcome to</span>
            <span className="block text-4xl font-bold">Multi-Signature Wallet</span>
          </h1>
          
          {/* Connection Status */}
          <div className="flex justify-center items-center space-x-2 flex-col mb-8">
            <p className="my-2 font-medium">Connected Address:</p>
            <Address address={connectedAddress} />
            {isOwner && (
              <div className="badge badge-success mt-2">Owner</div>
            )}
          </div>

          {/* Contract Overview */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
            <div className="stat bg-base-200 rounded-lg">
              <div className="stat-figure text-primary">
                <CurrencyDollarIcon className="h-8 w-8" />
              </div>
              <div className="stat-title">Contract Balance</div>
              <div className="stat-value text-primary">
                {contractBalance ? `${formatEther(contractBalance).toFixed(4)} CELO` : "Loading..."}
              </div>
            </div>
            
            <div className="stat bg-base-200 rounded-lg">
              <div className="stat-figure text-secondary">
                <UserGroupIcon className="h-8 w-8" />
              </div>
              <div className="stat-title">Owners</div>
              <div className="stat-value text-secondary">
                {owners ? owners.length : "Loading..."}
              </div>
            </div>
            
            <div className="stat bg-base-200 rounded-lg">
              <div className="stat-figure text-accent">
                <DocumentTextIcon className="h-8 w-8" />
              </div>
              <div className="stat-title">Required Confirmations</div>
              <div className="stat-value text-accent">
                {numConfirmationsRequired ? numConfirmationsRequired.toString() : "Loading..."}
              </div>
            </div>
          </div>



          {/* Submit Transaction Form */}
          {isOwner && (
            <div className="card bg-base-100 shadow-xl mb-8">
              <div className="card-body">
                <h2 className="card-title">
                  <PlusIcon className="h-6 w-6" />
                  Submit New Transaction
                </h2>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div className="form-control">
                    <label className="label">
                      <span className="label-text">Recipient Address</span>
                    </label>
                    <AddressInput
                      value={recipientAddress}
                      onChange={setRecipientAddress}
                      placeholder="0x..."
                    />
                  </div>
                  <div className="form-control">
                    <label className="label">
                      <span className="label-text">Amount (CELO)</span>
                    </label>
                    <EtherInput
                      value={transactionValue}
                      onChange={setTransactionValue}
                      placeholder="0.0"
                    />
                  </div>
                </div>
                <div className="form-control">
                  <label className="label">
                    <span className="label-text">Transaction Data (Optional)</span>
                  </label>
                  <input
                    type="text"
                    placeholder="0x..."
                    className="input input-bordered"
                    value={transactionData}
                    onChange={(e) => setTransactionData(e.target.value)}
                  />
                </div>
                <div className="card-actions justify-end">
                  <button
                    className="btn btn-primary"
                    onClick={handleSubmitTransaction}
                  >
                    Submit Transaction
                  </button>
                </div>
              </div>
            </div>
          )}

          {/* Transactions List */}
          <div className="card bg-base-100 shadow-xl">
            <div className="card-body">
              <h2 className="card-title">
                <DocumentTextIcon className="h-6 w-6" />
                Contract Information
              </h2>
              
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <h3 className="text-lg font-semibold mb-4">Owners</h3>
                  {owners && owners.length > 0 ? (
                    <div className="space-y-2">
                      {owners.map((owner, index) => (
                        <div key={index} className="flex items-center gap-2">
                          <Address address={owner} />
                          {owner === connectedAddress && (
                            <div className="badge badge-success">You</div>
                          )}
                        </div>
                      ))}
                    </div>
                  ) : (
                    <p className="text-gray-500">Loading owners...</p>
                  )}
                </div>
                
                <div>
                  <h3 className="text-lg font-semibold mb-4">Transaction Management</h3>
                  <div className="space-y-4">
                    <div className="stat bg-base-200 rounded-lg">
                      <div className="stat-title">Total Transactions</div>
                      <div className="stat-value text-primary">
                        {transactionCount ? transactionCount.toString() : "0"}
                      </div>
                    </div>
                    
                    {isOwner && (
                      <div className="space-y-2">
                        <p className="text-sm text-gray-600">
                          As an owner, you can:
                        </p>
                        <ul className="text-sm space-y-1">
                          <li>• Submit new transactions</li>
                          <li>• Confirm pending transactions</li>
                          <li>• Execute transactions with sufficient confirmations</li>
                          <li>• Revoke your confirmations</li>
                        </ul>
                      </div>
                    )}
                  </div>
                </div>
              </div>
              
              {transactionCount && Number(transactionCount) > 0 && (
                <div className="mt-6">
                  <h3 className="text-lg font-semibold mb-4">Recent Transactions</h3>
                  <div className="alert alert-info">
                    <DocumentTextIcon className="h-6 w-6" />
                    <div>
                      <h4 className="font-bold">Transaction Details Available</h4>
                      <p>Use the Debug Contracts tab to view and interact with individual transactions.</p>
                    </div>
                  </div>
                </div>
              )}
            </div>
          </div>

          {/* Navigation Links */}
          <div className="grow bg-base-300 w-full mt-16 px-8 py-12">
            <div className="flex justify-center items-center gap-12 flex-col md:flex-row">
              <div className="flex flex-col bg-base-100 px-10 py-10 text-center items-center max-w-xs rounded-3xl">
                <BugAntIcon className="h-8 w-8 fill-secondary" />
                <p>
                  Tinker with your smart contract using the{" "}
                  <a href="/debug" className="link">
                    Debug Contracts
                  </a>{" "}
                  tab.
                </p>
              </div>
              <div className="flex flex-col bg-base-100 px-10 py-10 text-center items-center max-w-xs rounded-3xl">
                <MagnifyingGlassIcon className="h-8 w-8 fill-secondary" />
                <p>
                  Explore your local transactions with the{" "}
                  <a href="/blockexplorer" className="link">
                    Block Explorer
                  </a>{" "}
                  tab.
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </>
  );
};

export default Home;
