"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { useAccount } from "wagmi";
import { PlusIcon, ArrowLeftIcon } from "@heroicons/react/24/outline";
import Link from "next/link";
import { useScaffoldWriteContract } from "~~/hooks/scaffold-eth/useScaffoldWriteContract";
import { parseEther } from "viem";

const CreateCampaign = () => {
  const router = useRouter();
  const { address: connectedAddress } = useAccount();
  
  const [formData, setFormData] = useState({
    title: "",
    description: "",
    beneficiary: "",
    goal: "",
    durationInDays: "",
  });
  const [isSubmitting, setIsSubmitting] = useState(false);

  const { writeAsync: createCampaign } = useScaffoldWriteContract("DonationApp");

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!connectedAddress) {
      alert("Please connect your wallet first");
      return;
    }

    if (!formData.title || !formData.description || !formData.beneficiary || !formData.goal || !formData.durationInDays) {
      alert("Please fill in all fields");
      return;
    }

    // Validate beneficiary address
    if (!/^0x[a-fA-F0-9]{40}$/.test(formData.beneficiary)) {
      alert("Please enter a valid beneficiary address");
      return;
    }

    // Validate goal amount
    const goalAmount = parseFloat(formData.goal);
    if (isNaN(goalAmount) || goalAmount <= 0) {
      alert("Please enter a valid goal amount");
      return;
    }

    // Validate duration
    const duration = parseInt(formData.durationInDays);
    if (isNaN(duration) || duration <= 0 || duration > 365) {
      alert("Please enter a valid duration (1-365 days)");
      return;
    }

    setIsSubmitting(true);

    try {
      await createCampaign({
        functionName: "createCampaign",
        args: [
          formData.title,
          formData.description,
          formData.beneficiary as `0x${string}`,
          parseEther(formData.goal),
          BigInt(duration)
        ],
      });

      alert("Campaign created successfully!");
      router.push("/");
    } catch (error) {
      console.error("Error creating campaign:", error);
      alert("Failed to create campaign. Please try again.");
    } finally {
      setIsSubmitting(false);
    }
  };

  if (!connectedAddress) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-center">
          <h2 className="text-2xl font-bold mb-4">Connect Your Wallet</h2>
          <p className="text-base-content/70 mb-4">Please connect your wallet to create a campaign</p>
          <Link href="/" passHref className="btn btn-primary">
            Go Home
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div className="flex items-center flex-col grow pt-10">
      <div className="px-5 w-full max-w-2xl">
        <div className="mb-6">
          <Link href="/" passHref className="btn btn-ghost btn-sm mb-4">
            <ArrowLeftIcon className="h-4 w-4 mr-2" />
            Back to Home
          </Link>
          <h1 className="text-3xl font-bold flex items-center">
            <PlusIcon className="h-8 w-8 mr-3 text-primary" />
            Create New Campaign
          </h1>
          <p className="text-base-content/70 mt-2">
            Start a fundraising campaign to help others in need
          </p>
        </div>

        <div className="bg-base-100 rounded-lg p-6 shadow-lg">
          <form onSubmit={handleSubmit} className="space-y-6">
            <div className="form-control">
              <label className="label">
                <span className="label-text font-semibold">Campaign Title *</span>
              </label>
              <input
                type="text"
                name="title"
                placeholder="Enter campaign title"
                className="input input-bordered w-full"
                value={formData.title}
                onChange={handleInputChange}
                maxLength={100}
                required
              />
            </div>

            <div className="form-control">
              <label className="label">
                <span className="label-text font-semibold">Description *</span>
              </label>
              <textarea
                name="description"
                placeholder="Describe your campaign and why people should donate..."
                className="textarea textarea-bordered w-full"
                value={formData.description}
                onChange={handleInputChange}
                rows={4}
                maxLength={500}
                required
              />
              <label className="label">
                <span className="label-text-alt">{formData.description.length}/500 characters</span>
              </label>
            </div>

            <div className="form-control">
              <label className="label">
                <span className="label-text font-semibold">Beneficiary Address *</span>
              </label>
              <input
                type="text"
                name="beneficiary"
                placeholder="0x..."
                className="input input-bordered w-full font-mono"
                value={formData.beneficiary}
                onChange={handleInputChange}
                required
              />
              <label className="label">
                <span className="label-text-alt">The address that will receive the donations</span>
              </label>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="form-control">
                <label className="label">
                  <span className="label-text font-semibold">Funding Goal (CELO) *</span>
                </label>
                <input
                  type="number"
                  name="goal"
                  placeholder="10.0"
                  className="input input-bordered w-full"
                  value={formData.goal}
                  onChange={handleInputChange}
                  step="0.01"
                  min="0.01"
                  required
                />
              </div>

              <div className="form-control">
                <label className="label">
                  <span className="label-text font-semibold">Duration (Days) *</span>
                </label>
                <input
                  type="number"
                  name="durationInDays"
                  placeholder="30"
                  className="input input-bordered w-full"
                  value={formData.durationInDays}
                  onChange={handleInputChange}
                  min="1"
                  max="365"
                  required
                />
              </div>
            </div>

            <div className="alert alert-info">
              <div>
                <h3 className="font-bold">Important Information</h3>
                <div className="text-xs">
                  <ul className="list-disc list-inside mt-2 space-y-1">
                    <li>Platform fee: 2.5% of each donation</li>
                    <li>Campaigns cannot be cancelled once donations are received</li>
                    <li>Only the beneficiary can withdraw funds</li>
                    <li>Campaigns automatically expire after the deadline</li>
                  </ul>
                </div>
              </div>
            </div>

            <div className="flex gap-4">
              <button
                type="submit"
                className="btn btn-primary flex-1"
                disabled={isSubmitting}
              >
                {isSubmitting ? (
                  <>
                    <span className="loading loading-spinner loading-sm"></span>
                    Creating...
                  </>
                ) : (
                  <>
                    <PlusIcon className="h-5 w-5 mr-2" />
                    Create Campaign
                  </>
                )}
              </button>
              <Link href="/" passHref className="btn btn-outline flex-1">
                Cancel
              </Link>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
};

export default CreateCampaign; 