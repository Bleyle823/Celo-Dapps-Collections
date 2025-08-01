"use client";

import { useState, useEffect } from "react";
import type { NextPage } from "next";
import { useAccount } from "wagmi";
import { 
  DocumentTextIcon, 
  ChartBarIcon, 
  BanknotesIcon, 
  UserGroupIcon,
  PlusIcon,
  CheckIcon,
  XMarkIcon,
  MinusIcon
} from "@heroicons/react/24/outline";
import { Address } from "~~/components/scaffold-eth";
import { ProposalCard } from "~~/components/scaffold-eth/ProposalCard";
import { TokenManager } from "~~/components/scaffold-eth/TokenManager";
import { useScaffoldReadContract, useScaffoldWriteContract } from "~~/hooks/scaffold-eth";
import { parseEther, formatEther } from "viem";

const Home: NextPage = () => {
  const { address: connectedAddress } = useAccount();
  const [activeTab, setActiveTab] = useState("proposals");
  const [proposals, setProposals] = useState<any[]>([]);
  const [daoSettings, setDaoSettings] = useState<any>(null);
  const [userVotingPower, setUserVotingPower] = useState("0");
  const [isMember, setIsMember] = useState(false);
  const [treasuryBalance, setTreasuryBalance] = useState("0");
  
  // Modal states
  const [showCreateProposal, setShowCreateProposal] = useState(false);
  const [proposalForm, setProposalForm] = useState({
    title: "",
    description: "",
    target: "",
    value: ""
  });
  const [depositAmount, setDepositAmount] = useState("");

  // Contract reads
  const { data: totalProposals } = useScaffoldReadContract({
    contractName: "SimpleDAO",
    functionName: "getTotalProposals",
  });

  const { data: settings } = useScaffoldReadContract({
    contractName: "SimpleDAO",
    functionName: "getDAOSettings",
  });

  const { data: userPower } = useScaffoldReadContract({
    contractName: "SimpleDAO",
    functionName: "getVotingPower",
    args: [connectedAddress],
  });

  const { data: userMembership } = useScaffoldReadContract({
    contractName: "SimpleDAO",
    functionName: "isMember",
    args: [connectedAddress],
  });

  const { data: treasury } = useScaffoldReadContract({
    contractName: "SimpleDAO",
    functionName: "treasuryBalance",
  });

  // Contract writes
  const { writeContractAsync: writeSimpleDAO } = useScaffoldWriteContract({
    contractName: "SimpleDAO",
  });

  const { writeContractAsync: writeGovernanceToken } = useScaffoldWriteContract({
    contractName: "GovernanceToken",
  });

  // Load proposals
  useEffect(() => {
    if (totalProposals) {
      loadProposals();
    }
  }, [totalProposals]);

  // Update state when data changes
  useEffect(() => {
    if (settings) {
      setDaoSettings({
        votingDelay: Number(settings[0]),
        votingPeriod: Number(settings[1]),
        proposalThreshold: formatEther(settings[2]),
        quorumThreshold: Number(settings[3]),
        passingThreshold: Number(settings[4]),
        treasuryBalance: formatEther(settings[5]),
      });
    }
  }, [settings]);

  useEffect(() => {
    if (userPower) {
      setUserVotingPower(formatEther(userPower));
    }
  }, [userPower]);

  useEffect(() => {
    if (userMembership !== undefined) {
      setIsMember(userMembership);
    }
  }, [userMembership]);

  useEffect(() => {
    if (treasury) {
      setTreasuryBalance(formatEther(treasury));
    }
  }, [treasury]);

  const loadProposals = async () => {
    if (!totalProposals) return;
    
    const proposalList = [];
    for (let i = 0; i < Number(totalProposals); i++) {
      try {
        // We'll need to use a different approach since getProposal is a read function
        // For now, we'll create a placeholder structure
        proposalList.push({
          id: i,
          title: `Proposal ${i}`,
          description: "Proposal description will be loaded here",
          proposer: "0x0000000000000000000000000000000000000000",
          startTime: Date.now() / 1000,
          endTime: Date.now() / 1000 + 86400 * 7,
          votesFor: 0n,
          votesAgainst: 0n,
          votesAbstain: 0n,
          executed: false,
          canceled: false,
        });
      } catch (error) {
        console.error(`Error loading proposal ${i}:`, error);
      }
    }
    setProposals(proposalList);
  };

  const joinDAO = async () => {
    try {
      await writeSimpleDAO({
        functionName: "joinDAO",
      });
    } catch (error) {
      console.error("Error joining DAO:", error);
    }
  };

  const handleCreateProposal = async () => {
    try {
      await writeSimpleDAO({
        functionName: "createProposal",
        args: [
          proposalForm.title,
          proposalForm.description,
          proposalForm.target || "0x0000000000000000000000000000000000000000",
          parseEther(proposalForm.value || "0"),
          "0x"
        ],
      });
      setShowCreateProposal(false);
      setProposalForm({ title: "", description: "", target: "", value: "" });
      // Reload proposals after creation
      setTimeout(() => {
        if (totalProposals) {
          loadProposals();
        }
      }, 2000);
    } catch (error) {
      console.error("Error creating proposal:", error);
    }
  };

  const castVote = async (proposalId: number, voteType: number) => {
    try {
      await writeSimpleDAO({
        functionName: "castVote",
        args: [BigInt(proposalId), BigInt(voteType)],
      });
    } catch (error) {
      console.error("Error casting vote:", error);
    }
  };

  const executeProposal = async (proposalId: number) => {
    try {
      await writeSimpleDAO({
        functionName: "executeProposal",
        args: [BigInt(proposalId)],
      });
    } catch (error) {
      console.error("Error executing proposal:", error);
    }
  };

  const handleDepositToTreasury = async () => {
    if (!depositAmount || parseFloat(depositAmount) <= 0) return;
    
    try {
      await writeSimpleDAO({
        functionName: "depositToTreasury",
        value: parseEther(depositAmount),
      });
      setDepositAmount("");
      // Reload treasury balance after deposit
      setTimeout(() => {
        if (treasury) {
          setTreasuryBalance(formatEther(treasury));
        }
      }, 2000);
    } catch (error) {
      console.error("Error depositing to treasury:", error);
    }
  };

  const getProposalState = (proposal: any) => {
    if (proposal.canceled) return "Canceled";
    if (proposal.executed) return "Executed";
    if (Date.now() / 1000 < Number(proposal.startTime)) return "Pending";
    if (Date.now() / 1000 <= Number(proposal.endTime)) return "Active";
    return "Ended";
  };

  const formatDate = (timestamp: number) => {
    return new Date(timestamp * 1000).toLocaleString();
  };

  return (
    <>
      <div className="flex items-center flex-col grow pt-10">
        <div className="px-5 w-full max-w-7xl">
          <h1 className="text-center mb-8">
            <span className="block text-2xl mb-2">Welcome to</span>
            <span className="block text-4xl font-bold">Basic DAO</span>
          </h1>

          {/* User Info */}
          <div className="bg-base-100 rounded-lg p-6 mb-6">
            <div className="flex justify-between items-center">
              <div>
                <p className="text-sm opacity-70">Connected Address:</p>
                <Address address={connectedAddress} />
              </div>
              <div className="text-right">
                <p className="text-sm opacity-70">Voting Power:</p>
                <p className="text-lg font-bold">{userVotingPower} tokens</p>
                <p className="text-sm opacity-70">Member: {isMember ? "Yes" : "No"}</p>
              </div>
            </div>
            {!isMember && connectedAddress && (
              <button
                onClick={joinDAO}
                className="btn btn-primary mt-4"
              >
                Join DAO
              </button>
            )}
          </div>

          {/* Navigation Tabs */}
          <div className="tabs tabs-boxed mb-6">
            <button
              className={`tab ${activeTab === "proposals" ? "tab-active" : ""}`}
              onClick={() => setActiveTab("proposals")}
            >
              <DocumentTextIcon className="h-5 w-5 mr-2" />
              Proposals
            </button>
            <button
              className={`tab ${activeTab === "treasury" ? "tab-active" : ""}`}
              onClick={() => setActiveTab("treasury")}
            >
              <BanknotesIcon className="h-5 w-5 mr-2" />
              Treasury
            </button>
            <button
              className={`tab ${activeTab === "governance" ? "tab-active" : ""}`}
              onClick={() => setActiveTab("governance")}
            >
              <ChartBarIcon className="h-5 w-5 mr-2" />
              Governance
            </button>
            <button
              className={`tab ${activeTab === "members" ? "tab-active" : ""}`}
              onClick={() => setActiveTab("members")}
            >
              <UserGroupIcon className="h-5 w-5 mr-2" />
              Members
            </button>
          </div>

          {/* Tab Content */}
          <div className="bg-base-100 rounded-lg p-6">
            {activeTab === "proposals" && (
              <div>
                <div className="flex justify-between items-center mb-6">
                  <h2 className="text-2xl font-bold">Proposals</h2>
                  <button 
                    className="btn btn-primary"
                    onClick={() => setShowCreateProposal(true)}
                  >
                    <PlusIcon className="h-5 w-5 mr-2" />
                    Create Proposal
                  </button>
                </div>
                
                <div className="space-y-6">
                  {proposals.length === 0 ? (
                    <div className="text-center py-12">
                      <div className="max-w-md mx-auto">
                        <DocumentTextIcon className="h-16 w-16 mx-auto mb-4 opacity-50" />
                        <h3 className="text-lg font-semibold mb-2">No proposals yet</h3>
                        <p className="opacity-70 mb-4">Be the first to create a proposal and start governing the DAO!</p>
                        <button 
                          className="btn btn-primary"
                          onClick={() => setShowCreateProposal(true)}
                        >
                          <PlusIcon className="h-5 w-5 mr-2" />
                          Create First Proposal
                        </button>
                      </div>
                    </div>
                  ) : (
                    proposals.map((proposal, index) => (
                      <ProposalCard
                        key={index}
                        proposal={proposal}
                        index={index}
                        isMember={isMember}
                        onVote={castVote}
                        onExecute={executeProposal}
                      />
                    ))
                  )}
                </div>
              </div>
            )}

            {activeTab === "treasury" && (
              <div>
                <h2 className="text-2xl font-bold mb-6">Treasury</h2>
                <div className="grid md:grid-cols-2 gap-6">
                  <div className="bg-base-200 rounded-lg p-6">
                    <h3 className="text-lg font-semibold mb-4">Treasury Balance</h3>
                    <p className="text-3xl font-bold">{treasuryBalance} ETH</p>
                  </div>
                  <div className="bg-base-200 rounded-lg p-6">
                    <h3 className="text-lg font-semibold mb-4">Deposit to Treasury</h3>
                    <div className="flex gap-2">
                      <input
                        type="number"
                        placeholder="Amount in ETH"
                        className="input input-bordered flex-1"
                        step="0.01"
                        min="0"
                        value={depositAmount}
                        onChange={(e) => setDepositAmount(e.target.value)}
                      />
                      <button 
                        className="btn btn-primary"
                        onClick={handleDepositToTreasury}
                        disabled={!depositAmount || parseFloat(depositAmount) <= 0}
                      >
                        Deposit
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            )}

            {activeTab === "governance" && (
              <div>
                <h2 className="text-2xl font-bold mb-6">Governance Settings</h2>
                
                {/* Token Management */}
                <div className="mb-8">
                  <TokenManager />
                </div>
                
                {/* DAO Settings */}
                {daoSettings && (
                  <div>
                    <h3 className="text-lg font-semibold mb-4">DAO Parameters</h3>
                    <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-4">
                      <div className="bg-base-200 rounded-lg p-4">
                        <p className="opacity-70">Voting Delay</p>
                        <p className="text-lg font-semibold">{daoSettings.votingDelay / 86400} days</p>
                      </div>
                      <div className="bg-base-200 rounded-lg p-4">
                        <p className="opacity-70">Voting Period</p>
                        <p className="text-lg font-semibold">{daoSettings.votingPeriod / 86400} days</p>
                      </div>
                      <div className="bg-base-200 rounded-lg p-4">
                        <p className="opacity-70">Proposal Threshold</p>
                        <p className="text-lg font-semibold">{daoSettings.proposalThreshold} tokens</p>
                      </div>
                      <div className="bg-base-200 rounded-lg p-4">
                        <p className="opacity-70">Quorum Threshold</p>
                        <p className="text-lg font-semibold">{daoSettings.quorumThreshold}%</p>
                      </div>
                      <div className="bg-base-200 rounded-lg p-4">
                        <p className="opacity-70">Passing Threshold</p>
                        <p className="text-lg font-semibold">{daoSettings.passingThreshold}%</p>
                      </div>
                    </div>
                  </div>
                )}
              </div>
            )}

            {activeTab === "members" && (
              <div>
                <h2 className="text-2xl font-bold mb-6">DAO Members</h2>
                <div className="bg-base-200 rounded-lg p-6">
                  <p className="text-center opacity-70">
                    Member information will be displayed here. 
                    Members are addresses that have joined the DAO and hold governance tokens.
                  </p>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Create Proposal Modal */}
      {showCreateProposal && (
        <div className="modal modal-open">
          <div className="modal-box">
            <h3 className="font-bold text-lg mb-4">Create New Proposal</h3>
            <div className="space-y-4">
              <div>
                <label className="label">
                  <span className="label-text">Title</span>
                </label>
                <input
                  type="text"
                  placeholder="Proposal title"
                  className="input input-bordered w-full"
                  value={proposalForm.title}
                  onChange={(e) => setProposalForm({...proposalForm, title: e.target.value})}
                />
              </div>
              <div>
                <label className="label">
                  <span className="label-text">Description</span>
                </label>
                <textarea
                  placeholder="Proposal description"
                  className="textarea textarea-bordered w-full"
                  rows={3}
                  value={proposalForm.description}
                  onChange={(e) => setProposalForm({...proposalForm, description: e.target.value})}
                />
              </div>
              <div>
                <label className="label">
                  <span className="label-text">Target Contract (optional)</span>
                </label>
                <input
                  type="text"
                  placeholder="0x..."
                  className="input input-bordered w-full"
                  value={proposalForm.target}
                  onChange={(e) => setProposalForm({...proposalForm, target: e.target.value})}
                />
              </div>
              <div>
                <label className="label">
                  <span className="label-text">ETH Value (optional)</span>
                </label>
                <input
                  type="number"
                  placeholder="0.0"
                  className="input input-bordered w-full"
                  step="0.01"
                  min="0"
                  value={proposalForm.value}
                  onChange={(e) => setProposalForm({...proposalForm, value: e.target.value})}
                />
              </div>
            </div>
            <div className="modal-action">
              <button 
                className="btn"
                onClick={() => setShowCreateProposal(false)}
              >
                Cancel
              </button>
              <button 
                className="btn btn-primary"
                onClick={handleCreateProposal}
                disabled={!proposalForm.title || !proposalForm.description}
              >
                Create Proposal
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
};

export default Home;
