const Meta = artifacts.require("Meta");
const Token = artifacts.require("Token");
const MainToken = artifacts.require("MainToken");
const Depository = artifacts.require("Depository");
const Settings = artifacts.require("Settings");
const FutureContract = artifacts.require("FutureContract");
const Redeployer = artifacts.require("Redeployer");
const PaymentSplitter = artifacts.require("PaymentSplitter");
const Sale = artifacts.require("Sale");
const name = 'EhterHedge';
const description = 'Decentralized Derivative Platform';
const urlWebVersion = 'http://0.0.0.0/';
const urlDownloadVersion = '';
const urlMobileVersion = '';
const author = 'arct';
const keywords = ['0x68656c6c6f0000000000000000000000'];
const tokenName = 'EtherHedge Rekt Token';
const tokenSymbol = 'REKT';
const decimal = 18;
const tokenNameSale = 'EtherHedge Token';
const tokenSymbolSale = 'EHE';
const priceFeedSource = '0xa5aA4e07F5255E14F02B385b1f04b35cC50bdb66'; // medianizer address kovan
const openingTime = Math.floor(Date.now()/1000)  + 1  ;
const closingTime = Math.floor(Date.now()/1000) + 3*3600*24;
const initialRate = 1000000;
const finalRate = 2500;

//settings
activationIn = 0;

//depository
liquidationProfit = 50;
feeDiscountIndex = 100;

//future contract
const ticker = 'ETHUSD';
const number = 1;
const maxOrderValue = 100000;
const minOrderValue = 100000000000000;
const percentMultiplyer = 100;
const maxLeverage = 50;
const maxMarketLength = 50;
const bancrupcyDiff = 10;

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

        await deployer.deploy(Settings, 
        	activationIn,
        	liquidationProfit,
        	feeDiscountIndex,
        	maxMarketLength,
            maxLeverage	
        	);

        await deployer.deploy(Depository, 
        	Settings.address, 
        	Token.address,
            MainToken.address,
        	percentMultiplyer,
            priceFeedSource,
        	);

        await deployer.deploy(Redeployer);

        await deployer.deploy(FutureContract, 
        	Settings.address, 
        	Depository.address,
        	decimal,
        	maxOrderValue,
        	minOrderValue,
        	percentMultiplyer,
        	bancrupcyDiff,
        	ticker,
            number,
            Redeployer.address
        	);

        await deployer.deploy(Meta, 
            name, 
            description,
            author,
            urlWebVersion,
            urlDownloadVersion,
            urlMobileVersion,
            Depository.address,
            Settings.address,
            Settings.address,
            keywords
            );

        const MainTokenInstance = await MainToken.deployed();
        await MainTokenInstance.addMinter(Sale.address);
        await MainTokenInstance.renounceMinter();

		const TokenInstance = await Token.deployed();
		await TokenInstance.addMinter(Depository.address);
		await TokenInstance.renounceMinter();
        
    })
};

