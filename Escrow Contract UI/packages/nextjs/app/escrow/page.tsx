import { EscrowInterface } from "./_components/EscrowInterface";
import type { NextPage } from "next";
import { getMetadata } from "~~/utils/scaffold-eth/getMetadata";

export const metadata = getMetadata({
  title: "Escrow Interface",
  description: "Interact with the SimpleEscrow smart contract",
});

const Escrow: NextPage = () => {
  return (
    <>
      <EscrowInterface />
      <div className="text-center mt-8 bg-secondary p-10">
        <h1 className="text-4xl my-0">Escrow Interface</h1>
        <p className="text-neutral">
          Create and manage escrow transactions with the SimpleEscrow smart contract.
          <br /> This interface allows buyers, sellers, and arbiters to interact with escrow contracts.
        </p>
      </div>
    </>
  );
};

export default Escrow; 