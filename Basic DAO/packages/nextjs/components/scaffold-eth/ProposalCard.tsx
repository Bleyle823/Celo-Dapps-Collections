import { useState } from "react";
import { CheckIcon, XMarkIcon, MinusIcon } from "@heroicons/react/24/outline";
import { Address } from "./Address/Address";
import { useScaffoldWriteContract } from "~~/hooks/scaffold-eth";
import { formatEther } from "viem";

interface ProposalCardProps {
  proposal: any;
  index: number;
  isMember: boolean;
  onVote: (proposalId: number, voteType: number) => void;
  onExecute: (proposalId: number) => void;
}

export const ProposalCard = ({ proposal, index, isMember, onVote, onExecute }: ProposalCardProps) => {
  const [isVoting, setIsVoting] = useState(false);
  const [isExecuting, setIsExecuting] = useState(false);

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

  const getStateBadgeClass = (state: string) => {
    switch (state) {
      case "Active":
        return "badge-success";
      case "Executed":
        return "badge-info";
      case "Canceled":
        return "badge-error";
      default:
        return "badge-warning";
    }
  };

  const handleVote = async (voteType: number) => {
    setIsVoting(true);
    try {
      await onVote(index, voteType);
    } finally {
      setIsVoting(false);
    }
  };

  const handleExecute = async () => {
    setIsExecuting(true);
    try {
      await onExecute(index);
    } finally {
      setIsExecuting(false);
    }
  };

  const state = getProposalState(proposal);
  const totalVotes = Number(proposal.votesFor || 0) + Number(proposal.votesAgainst || 0) + Number(proposal.votesAbstain || 0);
  const forPercentage = totalVotes > 0 ? (Number(proposal.votesFor || 0) / totalVotes) * 100 : 0;
  const againstPercentage = totalVotes > 0 ? (Number(proposal.votesAgainst || 0) / totalVotes) * 100 : 0;

  return (
    <div className="border rounded-lg p-6 hover:shadow-lg transition-shadow">
      <div className="flex justify-between items-start mb-4">
        <div className="flex-1">
          <h3 className="text-xl font-semibold mb-2">{proposal.title}</h3>
          <p className="text-sm opacity-70 mb-3">{proposal.description}</p>
        </div>
        <span className={`badge ${getStateBadgeClass(state)} ml-4`}>
          {state}
        </span>
      </div>

      {/* Proposal Details */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-4 text-sm">
        <div>
          <p className="opacity-70 font-medium">Proposer</p>
          <Address address={proposal.proposer} />
        </div>
        <div>
          <p className="opacity-70 font-medium">Start Time</p>
          <p>{formatDate(Number(proposal.startTime))}</p>
        </div>
        <div>
          <p className="opacity-70 font-medium">End Time</p>
          <p>{formatDate(Number(proposal.endTime))}</p>
        </div>
        <div>
          <p className="opacity-70 font-medium">Proposal ID</p>
          <p className="font-mono">#{proposal.id}</p>
        </div>
      </div>

      {/* Voting Results */}
      {totalVotes > 0 && (
        <div className="mb-4">
          <p className="opacity-70 font-medium mb-2">Voting Results</p>
          <div className="space-y-2">
            <div className="flex justify-between items-center">
              <span className="text-sm">For</span>
              <span className="text-sm font-medium">{formatEther(proposal.votesFor)} ({forPercentage.toFixed(1)}%)</span>
            </div>
            <div className="w-full bg-base-300 rounded-full h-2">
              <div 
                className="bg-success h-2 rounded-full transition-all duration-300" 
                style={{ width: `${forPercentage}%` }}
              ></div>
            </div>
            
            <div className="flex justify-between items-center">
              <span className="text-sm">Against</span>
              <span className="text-sm font-medium">{formatEther(proposal.votesAgainst)} ({againstPercentage.toFixed(1)}%)</span>
            </div>
            <div className="w-full bg-base-300 rounded-full h-2">
              <div 
                className="bg-error h-2 rounded-full transition-all duration-300" 
                style={{ width: `${againstPercentage}%` }}
              ></div>
            </div>
            
            <div className="flex justify-between items-center">
              <span className="text-sm">Abstain</span>
              <span className="text-sm font-medium">{formatEther(proposal.votesAbstain)}</span>
            </div>
          </div>
        </div>
      )}

      {/* Action Buttons */}
      <div className="flex flex-wrap gap-2">
        {state === "Active" && isMember && (
          <>
            <button
              onClick={() => handleVote(1)}
              disabled={isVoting}
              className="btn btn-success btn-sm"
            >
              <CheckIcon className="h-4 w-4 mr-1" />
              {isVoting ? "Voting..." : "Vote For"}
            </button>
            <button
              onClick={() => handleVote(0)}
              disabled={isVoting}
              className="btn btn-error btn-sm"
            >
              <XMarkIcon className="h-4 w-4 mr-1" />
              {isVoting ? "Voting..." : "Vote Against"}
            </button>
            <button
              onClick={() => handleVote(2)}
              disabled={isVoting}
              className="btn btn-warning btn-sm"
            >
              <MinusIcon className="h-4 w-4 mr-1" />
              {isVoting ? "Voting..." : "Abstain"}
            </button>
          </>
        )}
        
        {state === "Ended" && !proposal.executed && !proposal.canceled && (
          <button
            onClick={handleExecute}
            disabled={isExecuting}
            className="btn btn-primary btn-sm"
          >
            {isExecuting ? "Executing..." : "Execute Proposal"}
          </button>
        )}
      </div>
    </div>
  );
}; 