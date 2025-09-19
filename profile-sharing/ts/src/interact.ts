import { readFileSync } from 'fs';
import { join } from 'path';
import { getInitialTestAccountsWallets } from '@aztec/accounts/testing';
import { createPXEClient, waitForPXE, Contract, AztecAddress, Fr, loadContractArtifact } from '@aztec/aztec.js';
import ArtifactJson from '../../contract/target/profile_sharing-ProfileSharing.json' assert { type: 'json' };

const ADDR_PATH = join(process.cwd(), 'addresses.json');
const PXE_URL = process.env.PXE_URL || 'http://localhost:8080';

function strToFr(s: string) {
  const hex = Buffer.from(s, 'utf8').toString('hex') || '00';
  return Fr.fromString('0x' + hex);
}

async function main() {
  const pxe = createPXEClient(PXE_URL);
  await waitForPXE(pxe);

  const { profileSharing } = JSON.parse(readFileSync(ADDR_PATH, 'utf8'));
  if (!profileSharing) throw new Error('No profileSharing address in addresses.json. Run npm run deploy');

  const wallets = await getInitialTestAccountsWallets(pxe);
  const artifact = loadContractArtifact(ArtifactJson);

  const [a, b] = wallets;
  const contract = await Contract.at(AztecAddress.fromString(profileSharing), artifact, a);

  // Create and share profiles
  //const profile = await contract.methods.create_profile(strToFr('Alice'), strToFr('NY dev'), 25, Fr.random()).send().wait();
  // await contract.methods.share_profile(b.getAddress(), strToFr('Alice'), strToFr('NY dev'), 25, Fr.random()).send().wait();
  const profile = await contract.methods.get_profile(a.getAddress()).simulate();
  console.log('Profile:', profile);

  console.log('Created and shared profile.');
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});


