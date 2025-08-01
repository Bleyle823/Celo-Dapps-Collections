"use client";

import Link from "next/link";
import type { NextPage } from "next";
import { useAccount } from "wagmi";
import { HeartIcon, PlusIcon, MagnifyingGlassIcon } from "@heroicons/react/24/outline";
import { Address } from "~~/components/scaffold-eth";
import { useScaffoldContract } from "~~/hooks/scaffold-eth/useScaffoldContract";
import { useScaffoldReadContract } from "~~/hooks/scaffold-eth/useScaffoldReadContract";
import { useScaffoldWriteContract } from "~~/hooks/scaffold-eth/useScaffoldWriteContract";
import { useState, useEffect } from "react";
import { parseEther, formatEther } from "viem";

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

const Home: NextPage = () => {
  const { address: connectedAddress } = useAccount();
  const [campaigns, setCampaigns] = useState<Campaign[]>([]);
  const [loading, setLoading] = useState(true);
  const [donationAmount, setDonationAmount] = useState("");
  const [donationMessage, setDonationMessage] = useState("");
  const [selectedCampaign, setSelectedCampaign] = useState<number | null>(null);

  const { data: contract } = useScaffoldContract({ contractName: "DonationApp" });
  const { data: platformStats } = useScaffoldReadContract({
    contractName: "DonationApp",
    functionName: "getPlatformStats",
  });

  const { writeAsync: donate } = useScaffoldWriteContract("DonationApp");

  // Fetch active campaigns
  const fetchCampaigns = async () => {
    if (!contract) return;
    
    try {
      const activeCampaignIds = await contract.read.getActiveCampaigns([0n, 10n]);
      const campaignPromises = activeCampaignIds.map(async (id: bigint) => {
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
      
      const campaignResults = await Promise.all(campaignPromises);
      setCampaigns(campaignResults);
    } catch (error) {
      console.error("Error fetching campaigns:", error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchCampaigns();
  }, [contract]);

  const handleDonate = async (campaignId: number) => {
    if (!donationAmount || !connectedAddress) return;
    
    try {
      await donate({
        functionName: "donate",
        args: [BigInt(campaignId), donationMessage],
        value: parseEther(donationAmount),
      });
      
      // Reset form and refresh campaigns
      setDonationAmount("");
      setDonationMessage("");
      setSelectedCampaign(null);
      setTimeout(fetchCampaigns, 2000); // Wait for transaction to be mined
    } catch (error) {
      console.error("Error making donation:", error);
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

  return (
    <>
      <div className="flex items-center flex-col grow pt-10">
        <div className="px-5 w-full max-w-6xl">
          <h1 className="text-center mb-8">
            <span className="block text-2xl mb-2">Welcome to</span>
            <span className="block text-4xl font-bold text-primary">Donation App</span>
          </h1>
          
          {connectedAddress && (
            <div className="flex justify-center items-center space-x-2 flex-col mb-8">
              <p className="my-2 font-medium">Connected Address:</p>
              <Address address={connectedAddress} />
            </div>
          )}

          {/* Platform Stats */}
          {platformStats && (
            <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-8">
              <div className="bg-base-100 p-4 rounded-lg text-center">
                <div className="text-2xl font-bold text-primary">{Number(platformStats[0])}</div>
                <div className="text-sm">Total Campaigns</div>
              </div>
              <div className="bg-base-100 p-4 rounded-lg text-center">
                <div className="text-2xl font-bold text-primary">
                  {formatEther(platformStats[1])} CELO
                </div>
                <div className="text-sm">Total Raised</div>
              </div>
              <div className="bg-base-100 p-4 rounded-lg text-center">
                <div className="text-2xl font-bold text-primary">{Number(platformStats[2])}</div>
                <div className="text-sm">Total Donations</div>
              </div>
              <div className="bg-base-100 p-4 rounded-lg text-center">
                <div className="text-2xl font-bold text-primary">{Number(platformStats[3]) / 100}%</div>
                <div className="text-sm">Platform Fee</div>
              </div>
            </div>
          )}

          {/* Create Campaign Button */}
          <div className="text-center mb-8">
            <Link href="/create-campaign" passHref className="btn btn-primary btn-lg">
              <PlusIcon className="h-6 w-6 mr-2" />
              Create New Campaign
            </Link>
          </div>

          {/* Active Campaigns */}
          <div className="mb-8">
            <h2 className="text-2xl font-bold mb-4 flex items-center">
              <HeartIcon className="h-6 w-6 mr-2 text-primary" />
              Active Campaigns
            </h2>
            
            {loading ? (
              <div className="text-center py-8">
                <span className="loading loading-spinner loading-lg"></span>
                <p className="mt-4">Loading campaigns...</p>
              </div>
            ) : campaigns.length === 0 ? (
              <div className="text-center py-8 bg-base-100 rounded-lg">
                <HeartIcon className="h-12 w-12 mx-auto text-base-300 mb-4" />
                <p className="text-lg">No active campaigns found</p>
                <p className="text-base-content/60">Be the first to create a campaign!</p>
              </div>
            ) : (
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                {campaigns.map((campaign) => (
                  <div key={campaign.id} className="bg-base-100 rounded-lg p-6 shadow-lg">
                    <h3 className="text-xl font-bold mb-2">{campaign.title}</h3>
                    <p className="text-base-content/70 mb-4 line-clamp-3">{campaign.description}</p>
                    
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
                      <button 
                        className="btn btn-primary btn-sm flex-1"
                        onClick={() => setSelectedCampaign(campaign.id)}
                      >
                        Donate
                      </button>
                      <Link href={`/campaign/${campaign.id}`} passHref className="btn btn-outline btn-sm">
                        <MagnifyingGlassIcon className="h-4 w-4" />
                      </Link>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>

        {/* Donation Modal */}
        {selectedCampaign && (
          <div className="modal modal-open">
            <div className="modal-box">
              <h3 className="font-bold text-lg mb-4">Make a Donation</h3>
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
                  onClick={() => handleDonate(selectedCampaign)}
                  disabled={!donationAmount}
                >
                  Donate
                </button>
                <button 
                  className="btn"
                  onClick={() => {
                    setSelectedCampaign(null);
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
    </>
  );
};

export default Home;
