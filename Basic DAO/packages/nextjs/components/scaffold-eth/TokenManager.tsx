import { useState } from "react";
import { useScaffoldReadContract, useScaffoldWriteContract } from "~~/hooks/scaffold-eth";
import { useAccount } from "wagmi";
import { formatEther, parseEther } from "viem";

export const TokenManager = () => {
  const { address: connectedAddress } = useAccount();
  const [mintAmount, setMintAmount] = useState("");
  const [isMinting, setIsMinting] = useState(false);

  const { data: tokenBalance } = useScaffoldReadContract({
    contractName: "GovernanceToken",
    functionName: "balanceOf",
    args: [connectedAddress],
  });

  const { data: tokenSymbol } = useScaffoldReadContract({
    contractName: "GovernanceToken",
    functionName: "symbol",
  });

  const { data: tokenName } = useScaffoldReadContract({
    contractName: "GovernanceToken",
    functionName: "name",
  });

  const { writeContractAsync: writeGovernanceToken } = useScaffoldWriteContract({
    contractName: "GovernanceToken",
  });

  const handleMint = async () => {
    if (!mintAmount || parseFloat(mintAmount) <= 0) return;
    
    setIsMinting(true);
    try {
      await writeGovernanceToken({
        functionName: "mint",
        args: [connectedAddress, parseEther(mintAmount)],
      });
      setMintAmount("");
    } catch (error) {
      console.error("Error minting tokens:", error);
    } finally {
      setIsMinting(false);
    }
  };

  return (
    <div className="bg-base-100 rounded-lg p-6">
      <h3 className="text-lg font-semibold mb-4">Governance Token Management</h3>
      
      <div className="grid md:grid-cols-2 gap-6">
        <div className="bg-base-200 rounded-lg p-4">
          <h4 className="font-medium mb-2">Token Info</h4>
          <div className="space-y-2 text-sm">
            <div className="flex justify-between">
              <span className="opacity-70">Name:</span>
              <span>{tokenName || "Loading..."}</span>
            </div>
            <div className="flex justify-between">
              <span className="opacity-70">Symbol:</span>
              <span>{tokenSymbol || "Loading..."}</span>
            </div>
            <div className="flex justify-between">
              <span className="opacity-70">Your Balance:</span>
              <span className="font-medium">
                {tokenBalance ? formatEther(tokenBalance) : "0"} {tokenSymbol || "tokens"}
              </span>
            </div>
          </div>
        </div>

        <div className="bg-base-200 rounded-lg p-4">
          <h4 className="font-medium mb-2">Mint Tokens (Testing)</h4>
          <p className="text-xs opacity-70 mb-3">
            Mint governance tokens for testing purposes. This is only available to the token owner.
          </p>
          <div className="flex gap-2">
            <input
              type="number"
              placeholder="Amount to mint"
              className="input input-bordered flex-1"
              step="0.1"
              min="0"
              value={mintAmount}
              onChange={(e) => setMintAmount(e.target.value)}
            />
            <button
              className="btn btn-primary btn-sm"
              onClick={handleMint}
              disabled={!mintAmount || parseFloat(mintAmount) <= 0 || isMinting}
            >
              {isMinting ? "Minting..." : "Mint"}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}; 