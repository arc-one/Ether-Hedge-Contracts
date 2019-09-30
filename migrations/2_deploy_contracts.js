const bs58 = require('bs58');

const percentMultiplyer = 100;
const leverageMultiplyer = 100;
const ETHDecimals = 1000000000000000000;

const Token = artifacts.require("Token");
const MainToken = artifacts.require("MainToken");
const Depository = artifacts.require("Depository");
const Settings = artifacts.require("Settings");
const FutureContract = artifacts.require("FutureContract");
const Redeployer = artifacts.require("Redeployer");
const PaymentSplitter = artifacts.require("PaymentSplitter");
const Sale = artifacts.require("Sale");
const tokenName = 'EtherHedge Rekt Token';
const tokenSymbol = 'REKT';
const decimal = 18;
const tokenNameSale = 'EtherHedge Token';
const tokenSymbolSale = 'EHE';

const initialRate = 1000000;
const finalRate = 2500;

const priceFeedSource = '0xa5aA4e07F5255E14F02B385b1f04b35cC50bdb66'; // medianizer address kovan

//params for deploying 
const  votingTime = 240; // seconds
const  activationIn = 240; // seconds
const  openingTime = Math.floor(Date.now()/1000) + 60*3; // deploy
const  paramProposalFee = 0.003 * ETHDecimals;
const  contractProposalFee = 0.005 * ETHDecimals;



//params for testing 
/*const  votingTime = 5; // seconds
const  activationIn = 5; // seconds
const openingTime = Math.floor(Date.now()/1000)  + 1; // test
const  paramProposalFee = 0.3 * ETHDecimals;
const  contractProposalFee = 0.5 * ETHDecimals;*/


const  closingTime = openingTime + 3*3600*24;
const  maxServicePayment = 0.2 * percentMultiplyer;
const  feeLimit = 0; 
const  feeMarket = 0 * percentMultiplyer;
const  maxLeverage = 50 * leverageMultiplyer; 
const  liquidationProfit = 50 * percentMultiplyer; 
const  minVotingPercent = 5 * percentMultiplyer;
const  blockVotingFee = 0.1 * ETHDecimals;
const  feeDiscountIndex = 100; //from 0 - 100
const  maxMarketLength = 50;
const  ipfs = "QmNXnCWPS2szLaQGVA6TFtiUAJB2YnFTJJFTXPGuc4wocQ";


//Future Contract
const ticker = 'ETHUSD';
const number = 1;
const maxOrderValue = 100000;
const minOrderValue = 100000000000000;
const bancrupcyDiff = 10;


const fromIPFSHash = hash => {
    const bytes = bs58.decode(hash);
    const multiHashId = 2;
    // remove the multihash hash id
    return bytes.slice(multiHashId, bytes.length);
};
const toIPFSHash = str => {
    // remove leading 0x
    const remove0x = str.slice(2, str.length);
    // add back the multihash id
    const bytes = Buffer.from(`1220${remove0x}`, "hex");
    const hash = bs58.encode(bytes);
    return hash;
};

const bytes32 = fromIPFSHash(ipfs);
const ipfsBytes = '0x'+bytes32.toString('hex');

module.exports = function(deployer) {

    deployer.then(async () => {

        await deployer.deploy(Token, 
            tokenName, 
            tokenSymbol, 
            decimal,
            );

        await deployer.deploy(MainToken, 
            tokenNameSale, 
            tokenSymbolSale, 
            decimal,
            );

        await deployer.deploy(PaymentSplitter, 
                ['0xca35b7d915458ef540ade6068dfe2f44e8fa733c', '0x14723a09acff6d2a60dcdf7aa4aff308fddc160c'], 
                [100, 30]
            );

        await deployer.deploy(Sale, 
                1,
                PaymentSplitter.address,
                MainToken.address,
                openingTime,
                closingTime,
                initialRate, 
                finalRate
            );
//"240","240","0","0","5000","5000","500","3000000000000000","5000000000000000","100","50","100000000000000000","20","0x733027fa45770FA3dA8D3ca31747407bE5105185","0xa5aA4e07F5255E14F02B385b1f04b35cC50bdb66","0x02d9db84e21354dd4cc160eca9d13fa6f1b1bb44324013204098ae24090e717d"
        await deployer.deploy(Settings, 
                votingTime,
                activationIn,
                feeLimit, 
                feeMarket,
                maxLeverage, 
                liquidationProfit,
                minVotingPercent,
                paramProposalFee.toString(),
                contractProposalFee.toString(),
                feeDiscountIndex,
                maxMarketLength,
                blockVotingFee.toString(),
                maxServicePayment,
                MainToken.address,
                priceFeedSource,
                ipfsBytes
        	);

        await deployer.deploy(Depository, 
        	Settings.address, 
        	Token.address,
            MainToken.address
        	);

        await deployer.deploy(Redeployer);
        
        await deployer.deploy(FutureContract, 
        	Settings.address, 
        	Depository.address,
        	decimal,
        	maxOrderValue,
        	minOrderValue,
        	bancrupcyDiff,
        	ticker,
            number,
            Redeployer.address
        	);


        const MainTokenInstance = await MainToken.deployed();
        await MainTokenInstance.addMinter(Sale.address);
        await MainTokenInstance.addMinter(Settings.address);
        await MainTokenInstance.renounceMinter();

		const TokenInstance = await Token.deployed();
		await TokenInstance.addMinter(Depository.address);
		await TokenInstance.renounceMinter();

        // Add Depository
        const SettingsInstance = await Settings.deployed();
        await SettingsInstance.setDepository(Depository.address);

        // Add first future contract
        const FutureContractInstance = await FutureContract.deployed();
        await SettingsInstance.addContract(FutureContractInstance.address, 2592000);
        
    })
};

