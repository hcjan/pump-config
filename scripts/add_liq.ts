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


 
// create a new SuiClient object pointing to the network you want to use
const suiClient = new SuiClient({ url: getFullnodeUrl('mainnet') });
 
const tx = new Transaction();
// Construct the target for the buy_token function
const createPoolTarget = `${config.packageId}::pump_fun::create_pool`;
// const [coin] = tx.splitCoins(tx.gas, [10000])
// tx.transferObjects([coin], '0xa059045fff6e3c9895804c8212da208e0e2368ba195adea02970b87b739e57df');
const pumpTokenObkject = "0xeb87a702e96c5e190b1df7cc02323d5d9924efc19f119069f888a2a6d04333f5"
const suiObject = "0xd2e2d583798ff459c56f72dc2b4b75999005cac8ba275ec94fda7757f144ea36"
// Add the buy_token move call to the transaction
tx.moveCall({
    target: createPoolTarget,
    arguments: [
        tx.object(config.clmm.pools), // TokenInfo object
        tx.object(config.clmm.globalConfig), // FeeConfig object
        tx.object(pumpTokenObkject), // Payment coin
        tx.object(suiObject),
        tx.object("0x6"),
    ],
});

tx.setGasBudget(30000000);

const result = await suiClient.signAndExecuteTransaction({ signer: keyPair, transaction: tx });
const res = await suiClient.waitForTransaction({ digest: result.digest });
console.log(res);





}
main().catch(console.error);    