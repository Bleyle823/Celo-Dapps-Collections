"use client";

import { useState, useEffect } from "react";
import { useParams, useRouter } from "next/navigation";
import { useAccount } from "wagmi";
import { ArrowLeftIcon, HeartIcon, UserIcon, CalendarIcon } from "@heroicons/react/24/outline";
import Link from "next/link";
import { Address } from "~~/components/scaffold-eth";
import { useScaffoldContract } from "~~/hooks/scaffold-eth/useScaffoldContract";
import { useScaffoldWriteContract } from "~~/hooks/scaffold-eth/useScaffoldWriteContract";
import { formatEther, parseEther } from "viem";

interface Campaign {
  id: number;
  title: string;
  description: string;
  beneficiary: string;
  goal: bigint;
  raised: bigint;
  deadline: bigint;
  active: boolean;
  goalReached: boolean;
  donorCount: bigint;
  creator: string;
  createdAt: bigint;
}

interface Donation {
  donor: string;
  amount: bigint;
  timestamp: bigint;
  campaignId: bigint;
  message: string;
}

const CampaignDetail = () => {
  const params = useParams();
  const router = useRouter();
  const { address: connectedAddress } = useAccount();
  
  const [campaign, setCampaign] = useState<Campaign | null>(null);
  const [donations, setDonations] = useState<Donation[]>([]);
  const [loading, setLoading] = useState(true);
  const [donationAmount, setDonationAmount] = useState("");
  const [donationMessage, setDonationMessage] = useState("");
  const [showDonationModal, setShowDonationModal] = useState(false);

  const { data: contract } = useScaffoldContract({ contractName: "DonationApp" });
  const { writeAsync: donate } = useScaffoldWriteContract("DonationApp");
  const { writeAsync: withdrawFunds } = useScaffoldWriteContract("DonationApp");

  const campaignId = Number(params.id);

  const fetchCampaignData = async () => {
    if (!contract || isNaN(campaignId)) return;
    
    try {
      const campaignData = await contract.read.getCampaign([BigInt(campaignId)]);
      const campaignDonations = await contract.read.getCampaignDonations([BigInt(campaignId)]);
      
      setCampaign({
        id: campaignId,
        title: campaignData[0],
        description: campaignData[1],
        beneficiary: campaignData[2],
        goal: campaignData[3],
        raised: campaignData[4],
        deadline: campaignData[5],
        active: campaignData[6],
        goalReached: campaignData[7],
        donorCount: campaignData[8],
        creator: campaignData[9],
        createdAt: campaignData[10],
      });
      
      setDonations(campaignDonations);
    } catch (error) {
      console.error("Error fetching campaign:", error);
      alert("Campaign not found");
      router.push("/");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchCampaignData();
  }, [contract, campaignId]);

  const handleDonate = async () => {
    if (!donationAmount || !connectedAddress) return;
    
    try {
      await donate({
        functionName: "donate",
        args: [BigInt(campaignId), donationMessage],
        value: parseEther(donationAmount),
      });
      
      // Reset form and refresh data
      setDonationAmount("");
      setDonationMessage("");
      setShowDonationModal(false);
      setTimeout(fetchCampaignData, 2000); // Wait for transaction to be mined
    } catch (error) {
      console.error("Error making donation:", error);
    }
  };

  const handleWithdraw = async () => {
    if (!campaign) return;
    
    try {
      await withdrawFunds({
        functionName: "withdrawFunds",
        args: [BigInt(campaignId)],
      });
      alert("Funds withdrawn successfully!");
      setTimeout(fetchCampaignData, 2000);
    } catch (error) {
      console.error("Error withdrawing funds:", error);
      alert("Failed to withdraw funds. Please try again.");
    }
  };

  const formatTimeLeft = (deadline: bigint) => {
    const now = BigInt(Math.floor(Date.now() / 1000));
    const timeLeft = deadline - now;
    
    if (timeLeft <= 0n) return "Expired";
    
    const days = Number(timeLeft / 86400n);
    const hours = Number((timeLeft % 86400n) / 3600n);
    
    if (days > 0) return `${days}d ${hours}h left`;
    return `${hours}h left`;
  };

  const getProgressPercentage = (raised: bigint, goal: bigint) => {
    if (goal === 0n) return 0;
    const percentage = Number((raised * 100n) / goal);
    return Math.min(percentage, 100);
  };

  const formatDate = (timestamp: bigint) => {
    return new Date(Number(timestamp) * 1000).toLocaleDateString();
  };

  const isExpired = (deadline: bigint) => {
    const now = BigInt(Math.floor(Date.now() / 1000));
    return now > deadline;
  };

  const canWithdraw = campaign && 
    connectedAddress === campaign.beneficiary && 
    campaign.raised > 0n && 
    campaign.active && 
    !isExpired(campaign.deadline);

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-center">
          <span className="loading loading-spinner loading-lg"></span>
          <p className="mt-4">Loading campaign...</p>
        </div>
      </div>
    );
  }

  if (!campaign) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-center">
          <h2 className="text-2xl font-bold mb-4">Campaign Not Found</h2>
          <Link href="/" passHref className="btn btn-primary">
            Go Home
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div className="flex items-center flex-col grow pt-10">
      <div className="px-5 w-full max-w-4xl">
        <div className="mb-6">
          <Link href="/" passHref className="btn btn-ghost btn-sm mb-4">
            <ArrowLeftIcon className="h-4 w-4 mr-2" />
            Back to Home
          </Link>
        </div>

        {/* Campaign Header */}
        <div className="bg-base-100 rounded-lg p-6 shadow-lg mb-6">
          <div className="flex justify-between items-start mb-4">
            <h1 className="text-3xl font-bold">{campaign.title}</h1>
            <span className={`badge badge-lg ${campaign.active ? 'badge-success' : 'badge-error'}`}>
              {campaign.active ? 'Active' : 'Inactive'}
            </span>
          </div>
          
          <p className="text-lg text-base-content/70 mb-6">{campaign.description}</p>
          
          {/* Progress Bar */}
          <div className="mb-6">
            <div className="flex justify-between text-sm mb-2">
              <span>Progress</span>
              <span>{getProgressPercentage(campaign.raised, campaign.goal)}%</span>
            </div>
            <progress 
              className="progress progress-primary w-full h-4" 
              value={getProgressPercentage(campaign.raised, campaign.goal)} 
              max="100"
            ></progress>
          </div>
          
          {/* Stats Grid */}
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
            <div className="text-center">
              <div className="text-2xl font-bold text-primary">{formatEther(campaign.raised)} CELO</div>
              <div className="text-sm text-base-content/60">Raised</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold">{formatEther(campaign.goal)} CELO</div>
              <div className="text-sm text-base-content/60">Goal</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold">{Number(campaign.donorCount)}</div>
              <div className="text-sm text-base-content/60">Donors</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold">{formatTimeLeft(campaign.deadline)}</div>
              <div className="text-sm text-base-content/60">Time Left</div>
            </div>
          </div>
          
          {/* Action Buttons */}
          <div className="flex gap-4">
            {campaign.active && !isExpired(campaign.deadline) && (
              <button 
                className="btn btn-primary btn-lg flex-1"
                onClick={() => setShowDonationModal(true)}
              >
                <HeartIcon className="h-5 w-5 mr-2" />
                Donate Now
              </button>
            )}
            {canWithdraw && (
              <button 
                className="btn btn-secondary btn-lg"
                onClick={handleWithdraw}
              >
                Withdraw Funds
              </button>
            )}
          </div>
        </div>

        {/* Campaign Details */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
          <div className="bg-base-100 rounded-lg p-6 shadow-lg">
            <h2 className="text-xl font-bold mb-4 flex items-center">
              <UserIcon className="h-5 w-5 mr-2" />
              Campaign Creator
            </h2>
            <Address address={campaign.creator} />
            <p className="text-sm text-base-content/60 mt-2">
              Created on {formatDate(campaign.createdAt)}
            </p>
          </div>
          
          <div className="bg-base-100 rounded-lg p-6 shadow-lg">
            <h2 className="text-xl font-bold mb-4 flex items-center">
              <HeartIcon className="h-5 w-5 mr-2" />
              Beneficiary
            </h2>
            <Address address={campaign.beneficiary} />
            <p className="text-sm text-base-content/60 mt-2">
              Will receive all donations
            </p>
          </div>
        </div>

        {/* Donations List */}
        <div className="bg-base-100 rounded-lg p-6 shadow-lg">
          <h2 className="text-xl font-bold mb-4">Recent Donations</h2>
          {donations.length === 0 ? (
            <div className="text-center py-8">
              <HeartIcon className="h-12 w-12 mx-auto text-base-300 mb-4" />
              <p className="text-lg">No donations yet</p>
              <p className="text-base-content/60">Be the first to donate!</p>
            </div>
          ) : (
            <div className="space-y-4">
              {donations.slice(-10).reverse().map((donation, index) => (
                <div key={index} className="flex justify-between items-center p-4 bg-base-200 rounded-lg">
                  <div className="flex items-center gap-4">
                    <Address address={donation.donor} />
                    {donation.message && (
                      <p className="text-sm text-base-content/70">"{donation.message}"</p>
                    )}
                  </div>
                  <div className="text-right">
                    <div className="font-bold text-primary">{formatEther(donation.amount)} CELO</div>
                    <div className="text-xs text-base-content/60">{formatDate(donation.timestamp)}</div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* Donation Modal */}
      {showDonationModal && (
        <div className="modal modal-open">
          <div className="modal-box">
            <h3 className="font-bold text-lg mb-4">Make a Donation</h3>
            <p className="text-base-content/70 mb-4">
              Donating to: <strong>{campaign.title}</strong>
            </p>
            <div className="form-control">
              <label className="label">
                <span className="label-text">Amount (CELO)</span>
              </label>
              <input
                type="number"
                placeholder="0.1"
                className="input input-bordered"
                value={donationAmount}
                onChange={(e) => setDonationAmount(e.target.value)}
                step="0.01"
                min="0"
              />
            </div>
            <div className="form-control">
              <label className="label">
                <span className="label-text">Message (Optional)</span>
              </label>
              <textarea
                placeholder="Leave a message..."
                className="textarea textarea-bordered"
                value={donationMessage}
                onChange={(e) => setDonationMessage(e.target.value)}
                rows={3}
              />
            </div>
            <div className="modal-action">
              <button 
                className="btn btn-primary"
                onClick={handleDonate}
                disabled={!donationAmount}
              >
                Donate
              </button>
              <button 
                className="btn"
                onClick={() => {
                  setShowDonationModal(false);
                  setDonationAmount("");
                  setDonationMessage("");
                }}
              >
                Cancel
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default CampaignDetail; 