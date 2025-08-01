"use client";

import { useState, useEffect } from "react";
import { useAccount } from "wagmi";
import { UserIcon, ArrowLeftIcon, HeartIcon, EyeIcon } from "@heroicons/react/24/outline";
import Link from "next/link";
import { useScaffoldContract } from "~~/hooks/scaffold-eth/useScaffoldContract";
import { useScaffoldWriteContract } from "~~/hooks/scaffold-eth/useScaffoldWriteContract";
import { formatEther } from "viem";

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

const MyCampaigns = () => {
  const { address: connectedAddress } = useAccount();
  const [myCampaigns, setMyCampaigns] = useState<Campaign[]>([]);
  const [donatedCampaigns, setDonatedCampaigns] = useState<Campaign[]>([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState<'created' | 'donated'>('created');

  const { data: contract } = useScaffoldContract({ contractName: "DonationApp" });
  const { writeAsync: withdrawFunds } = useScaffoldWriteContract("DonationApp");
  const { writeAsync: cancelCampaign } = useScaffoldWriteContract("DonationApp");

  const fetchMyCampaigns = async () => {
    if (!contract || !connectedAddress) return;
    
    try {
      // Fetch campaigns created by user
      const createdCampaignIds = await contract.read.getUserCampaigns([connectedAddress]);
      const createdCampaignPromises = createdCampaignIds.map(async (id: bigint) => {
        const campaignData = await contract.read.getCampaign([id]);
        return {
          id: Number(id),
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
        };
      });
      
      const createdResults = await Promise.all(createdCampaignPromises);
      setMyCampaigns(createdResults);

      // Fetch campaigns user has donated to
      const donatedCampaignIds = await contract.read.getUserDonations([connectedAddress]);
      const donatedCampaignPromises = donatedCampaignIds.map(async (id: bigint) => {
        const campaignData = await contract.read.getCampaign([id]);
        return {
          id: Number(id),
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
        };
      });
      
      const donatedResults = await Promise.all(donatedCampaignPromises);
      setDonatedCampaigns(donatedResults);
    } catch (error) {
      console.error("Error fetching campaigns:", error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchMyCampaigns();
  }, [contract, connectedAddress]);

  const handleWithdraw = async (campaignId: number) => {
    try {
      await withdrawFunds({
        functionName: "withdrawFunds",
        args: [BigInt(campaignId)],
      });
      alert("Funds withdrawn successfully!");
      setTimeout(fetchMyCampaigns, 2000);
    } catch (error) {
      console.error("Error withdrawing funds:", error);
      alert("Failed to withdraw funds. Please try again.");
    }
  };

  const handleCancel = async (campaignId: number) => {
    if (!confirm("Are you sure you want to cancel this campaign? This action cannot be undone.")) {
      return;
    }

    try {
      await cancelCampaign({
        functionName: "cancelCampaign",
        args: [BigInt(campaignId)],
      });
      alert("Campaign cancelled successfully!");
      setTimeout(fetchMyCampaigns, 2000);
    } catch (error) {
      console.error("Error cancelling campaign:", error);
      alert("Failed to cancel campaign. Please try again.");
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

  const isExpired = (deadline: bigint) => {
    const now = BigInt(Math.floor(Date.now() / 1000));
    return now > deadline;
  };

  if (!connectedAddress) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-center">
          <h2 className="text-2xl font-bold mb-4">Connect Your Wallet</h2>
          <p className="text-base-content/70 mb-4">Please connect your wallet to view your campaigns</p>
          <Link href="/" passHref className="btn btn-primary">
            Go Home
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div className="flex items-center flex-col grow pt-10">
      <div className="px-5 w-full max-w-6xl">
        <div className="mb-6">
          <Link href="/" passHref className="btn btn-ghost btn-sm mb-4">
            <ArrowLeftIcon className="h-4 w-4 mr-2" />
            Back to Home
          </Link>
          <h1 className="text-3xl font-bold flex items-center">
            <UserIcon className="h-8 w-8 mr-3 text-primary" />
            My Campaigns
          </h1>
          <p className="text-base-content/70 mt-2">
            Manage your campaigns and track your donations
          </p>
        </div>

        {/* Tabs */}
        <div className="tabs tabs-boxed mb-6">
          <button 
            className={`tab ${activeTab === 'created' ? 'tab-active' : ''}`}
            onClick={() => setActiveTab('created')}
          >
            Created ({myCampaigns.length})
          </button>
          <button 
            className={`tab ${activeTab === 'donated' ? 'tab-active' : ''}`}
            onClick={() => setActiveTab('donated')}
          >
            Donated To ({donatedCampaigns.length})
          </button>
        </div>

        {loading ? (
          <div className="text-center py-8">
            <span className="loading loading-spinner loading-lg"></span>
            <p className="mt-4">Loading your campaigns...</p>
          </div>
        ) : (
          <div>
            {activeTab === 'created' && (
              <div>
                <h2 className="text-2xl font-bold mb-4">Campaigns You Created</h2>
                {myCampaigns.length === 0 ? (
                  <div className="text-center py-8 bg-base-100 rounded-lg">
                    <UserIcon className="h-12 w-12 mx-auto text-base-300 mb-4" />
                    <p className="text-lg">You haven't created any campaigns yet</p>
                    <Link href="/create-campaign" passHref className="btn btn-primary mt-4">
                      Create Your First Campaign
                    </Link>
                  </div>
                ) : (
                  <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                    {myCampaigns.map((campaign) => (
                      <div key={campaign.id} className="bg-base-100 rounded-lg p-6 shadow-lg">
                        <div className="flex justify-between items-start mb-2">
                          <h3 className="text-xl font-bold">{campaign.title}</h3>
                          <span className={`badge ${campaign.active ? 'badge-success' : 'badge-error'}`}>
                            {campaign.active ? 'Active' : 'Inactive'}
                          </span>
                        </div>
                        
                        <p className="text-base-content/70 mb-4 line-clamp-2">{campaign.description}</p>
                        
                        <div className="mb-4">
                          <div className="flex justify-between text-sm mb-1">
                            <span>Progress</span>
                            <span>{getProgressPercentage(campaign.raised, campaign.goal)}%</span>
                          </div>
                          <progress 
                            className="progress progress-primary w-full" 
                            value={getProgressPercentage(campaign.raised, campaign.goal)} 
                            max="100"
                          ></progress>
                        </div>
                        
                        <div className="grid grid-cols-2 gap-4 mb-4 text-sm">
                          <div>
                            <div className="font-semibold">{formatEther(campaign.raised)} CELO</div>
                            <div className="text-base-content/60">Raised</div>
                          </div>
                          <div>
                            <div className="font-semibold">{formatEther(campaign.goal)} CELO</div>
                            <div className="text-base-content/60">Goal</div>
                          </div>
                          <div>
                            <div className="font-semibold">{Number(campaign.donorCount)}</div>
                            <div className="text-base-content/60">Donors</div>
                          </div>
                          <div>
                            <div className="font-semibold">{formatTimeLeft(campaign.deadline)}</div>
                            <div className="text-base-content/60">Time Left</div>
                          </div>
                        </div>
                        
                        <div className="flex gap-2">
                          <Link href={`/campaign/${campaign.id}`} passHref className="btn btn-outline btn-sm flex-1">
                            <EyeIcon className="h-4 w-4 mr-1" />
                            View
                          </Link>
                          {campaign.active && campaign.raised > 0n && !isExpired(campaign.deadline) && (
                            <button 
                              className="btn btn-primary btn-sm"
                              onClick={() => handleWithdraw(campaign.id)}
                            >
                              Withdraw
                            </button>
                          )}
                          {campaign.active && campaign.raised === 0n && (
                            <button 
                              className="btn btn-error btn-sm"
                              onClick={() => handleCancel(campaign.id)}
                            >
                              Cancel
                            </button>
                          )}
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            )}

            {activeTab === 'donated' && (
              <div>
                <h2 className="text-2xl font-bold mb-4">Campaigns You Donated To</h2>
                {donatedCampaigns.length === 0 ? (
                  <div className="text-center py-8 bg-base-100 rounded-lg">
                    <HeartIcon className="h-12 w-12 mx-auto text-base-300 mb-4" />
                    <p className="text-lg">You haven't donated to any campaigns yet</p>
                    <Link href="/" passHref className="btn btn-primary mt-4">
                      Browse Campaigns
                    </Link>
                  </div>
                ) : (
                  <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                    {donatedCampaigns.map((campaign) => (
                      <div key={campaign.id} className="bg-base-100 rounded-lg p-6 shadow-lg">
                        <div className="flex justify-between items-start mb-2">
                          <h3 className="text-xl font-bold">{campaign.title}</h3>
                          <span className={`badge ${campaign.active ? 'badge-success' : 'badge-error'}`}>
                            {campaign.active ? 'Active' : 'Inactive'}
                          </span>
                        </div>
                        
                        <p className="text-base-content/70 mb-4 line-clamp-2">{campaign.description}</p>
                        
                        <div className="mb-4">
                          <div className="flex justify-between text-sm mb-1">
                            <span>Progress</span>
                            <span>{getProgressPercentage(campaign.raised, campaign.goal)}%</span>
                          </div>
                          <progress 
                            className="progress progress-primary w-full" 
                            value={getProgressPercentage(campaign.raised, campaign.goal)} 
                            max="100"
                          ></progress>
                        </div>
                        
                        <div className="grid grid-cols-2 gap-4 mb-4 text-sm">
                          <div>
                            <div className="font-semibold">{formatEther(campaign.raised)} CELO</div>
                            <div className="text-base-content/60">Raised</div>
                          </div>
                          <div>
                            <div className="font-semibold">{formatEther(campaign.goal)} CELO</div>
                            <div className="text-base-content/60">Goal</div>
                          </div>
                          <div>
                            <div className="font-semibold">{Number(campaign.donorCount)}</div>
                            <div className="text-base-content/60">Donors</div>
                          </div>
                          <div>
                            <div className="font-semibold">{formatTimeLeft(campaign.deadline)}</div>
                            <div className="text-base-content/60">Time Left</div>
                          </div>
                        </div>
                        
                        <Link href={`/campaign/${campaign.id}`} passHref className="btn btn-primary btn-sm w-full">
                          <EyeIcon className="h-4 w-4 mr-1" />
                          View Campaign
                        </Link>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
};

export default MyCampaigns; 