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
    console.log(keyPair.getPublicKey().toSuiAddress());
// replace <YOUR_SUI_ADDRESS> with your actual address, which is in the form 0x123...
const MY_ADDRESS = '0x12a42c161f48dce61594cec8475187ee60eebae84a1c97447920dd2b8c558a91';
 
// create a new SuiClient object pointing to the network you want to use
const suiClient = new SuiClient({ url: getFullnodeUrl('mainnet') });
 
const coins = await suiClient.getCoins({
    owner: MY_ADDRESS,
    coinType: '0x2::sui::SUI',
});
const tx = new Transaction();
// Construct the target for the buy_token function
const buyTokenTarget = `${config.packageId}::pump_fun::buy_token`;
// const [coin] = tx.splitCoins(tx.gas, [10000])
// tx.transferObjects([coin], keyPair.getPublicKey().toSuiAddress());

// Add the buy_token move call to the transaction
tx.moveCall({
    target: buyTokenTarget,
    arguments: [
        tx.object(config.tokenInfo), // TokenInfo object
        tx.object(config.feeConfig), // FeeConfig object
        tx.object("0x0fd9a2be3abcb1d7f2eec3a4fd9145839cf6f00848c0ce452639a6ff8116ee04"), // Payment coin
        bcs.U64.serialize(1000),
        tx.object(config.clmm.pools),
        tx.object(config.clmm.globalConfig),
        tx.object("0x6"),
    ],
});

tx.setGasBudget(50000000);

const result = await suiClient.signAndExecuteTransaction({ signer: keyPair, transaction: tx });
const res = await suiClient.waitForTransaction({ digest: result.digest });
console.log(res);



// const { bytes, signature } = tx.sign({ client, signer: keypair });
 
// const result = await client.executeTransactionBlock({
// 	transactionBlock: bytes,
// 	signature,
// 	requestType: 'WaitForLocalExecution',
// 	options: {
// 		showEffects: true,
// 	},
// });



}
main().catch(console.error);    