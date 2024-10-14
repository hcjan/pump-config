import { getFullnodeUrl, SuiClient } from '@mysten/sui/client';
import { getFaucetHost, requestSuiFromFaucetV1 } from '@mysten/sui/faucet';
import { MIST_PER_SUI } from '@mysten/sui/utils';
import { Transaction } from '@mysten/sui/transactions';
import { decodeSuiPrivateKey, encodeSuiPrivateKey } from '@mysten/sui/cryptography';
import { Ed25519Keypair } from '@mysten/sui/keypairs/ed25519';
import config from './config.json';
import { bcs } from '@mysten/sui/bcs';

import dotenv from 'dotenv';
dotenv.config();
async function main() {

const keyPair = Ed25519Keypair.fromSecretKey(process.env.SECRET_KEY as string);

// replace <YOUR_SUI_ADDRESS> with your actual address, which is in the form 0x123...
const MY_ADDRESS = '0x12a42c161f48dce61594cec8475187ee60eebae84a1c97447920dd2b8c558a91';
 
// create a new SuiClient object pointing to the network you want to use
const suiClient = new SuiClient({ url: getFullnodeUrl('mainnet') });
 
const coins = await suiClient.getCoins({
    owner: MY_ADDRESS,
    coinType: '0x2::sui::SUI',
});

const tokenType = `${config.packageId}::pump_fun::PUMP_FUN`;
const tokenCoins = await suiClient.getCoins({
    owner: MY_ADDRESS,
    coinType: tokenType,
});

console.log(coins);
console.log(tokenCoins);



}
main().catch(console.error);    