import { writeFileSync, existsSync, readFileSync } from 'fs';
import { getInitialTestAccountsWallets } from '@aztec/accounts/testing';
import { join } from 'path';
import { createPXEClient, waitForPXE, loadContractArtifact, Contract } from '@aztec/aztec.js';
import ArtifactJson from '../../contract/target/profile_sharing-ProfileSharing.json' with { type: "json" };

const ADDR_PATH = join(process.cwd(), 'addresses.json');
const PXE_URL = process.env.PXE_URL || 'http://localhost:8080';

async function main() {
  const pxe = createPXEClient(PXE_URL);
  await waitForPXE(pxe);

  // Try to reuse address if already deployed
  if (existsSync(ADDR_PATH)) {
    const cached = JSON.parse(readFileSync(ADDR_PATH, 'utf8'));
    if (cached.profileSharing) {
      console.log(`Using cached ProfileSharing at ${cached.profileSharing}`);
      return;
    }
  }

  // Use first test wallet
  const [ownerWallet] = await getInitialTestAccountsWallets(pxe);
  const artifact = loadContractArtifact(ArtifactJson);

  // Load artifact and deploy
  const contract = await Contract.deploy(ownerWallet, artifact, []).send().deployed();
  const address = contract.address.toString();
  console.log(`ProfileSharing deployed at ${address}`);

  writeFileSync(ADDR_PATH, JSON.stringify({ profileSharing: address }, null, 2));
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});


