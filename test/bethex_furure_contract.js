const Sale = artifacts.require("Sale");
const MainToken = artifacts.require("MainToken");
const FutureContract = artifacts.require("FutureContract");
const Settings = artifacts.require("Settings");
const Depository = artifacts.require("Depository");
const Meta = artifacts.require("Meta");
const Token = artifacts.require("Token");
const decimal = 1000000000000000000;
const decimalUsd = 1000000000;
const percentMultiplyer = 100;
const currentPrice = 140 * decimalUsd;

contract('ALL', (accounts) => {

	const accountOne = accounts[0];
	const accountTwo = accounts[1];
	const accountThree = accounts[2];
	const accountFour = accounts[3];
	const accountFive = accounts[4];

	var balanceAccountOne = 0;
	var balanceAccountTwo = 0;
	var balanceAccountThree = 0;
	var balanceAccountFour = 0;

	it('requestToAddContract(address account)', async () => {
		const SettingsInstance = await Settings.deployed();
		const FutureContractInstance = await FutureContract.deployed();
		const address = FutureContractInstance.address;
		await SettingsInstance.requestToAddContract(address, { from: accountOne});
		let equestedToAddContract = await SettingsInstance.requestedToAddContracts(address);
		assert.isDefined(equestedToAddContract, "requestToAddContract(address account) fail");
	});

	it('addContract(address account)', async () => {
		const SettingsInstance = await Settings.deployed();
		const FutureContractInstance = await FutureContract.deployed();
		const address = FutureContractInstance.address;
		await SettingsInstance.addContract(address, 7776000, { from: accountOne});
		let contractIsActive = await SettingsInstance.isContractTrusted(address);
		assert.isBoolean(contractIsActive, "Contract Is Not Active");
	});

	it('deposit() should deposit 5 Eth for the first 4 accounts', async () => {
		const DepositoryInstance = await Depository.deployed();
		const amount = 5 * decimal;
		
		balanceAccountOne = amount;
		balanceAccountTwo = amount;
		balanceAccountThree = amount;
		balanceAccountFour = amount;
		
		await DepositoryInstance.deposit({ from: accountOne, value: amount.toString() });
		await DepositoryInstance.deposit({ from: accountTwo, value: amount.toString() });
		await DepositoryInstance.deposit({ from: accountThree, value: amount.toString() });
		await DepositoryInstance.deposit({ from: accountFour, value: amount.toString() });
		
		let balanceOne = await DepositoryInstance.getBalance(accountOne);
		let balanceTwo = await DepositoryInstance.getBalance(accountTwo);
		let balanceThree = await DepositoryInstance.getBalance(accountThree);
		let balanceFour = await DepositoryInstance.getBalance(accountFour);
		
		assert.equal(balanceOne, amount, "accountOne not deposited 5 Eth to the contract");
		assert.equal(balanceTwo, amount, "accountTwo not deposited 5 Eth to the contract");
		assert.equal(balanceThree, amount, "accountThree not deposited 5 Eth to the contract");
		assert.equal(balanceFour, amount, "accountFour not deposited 5 Eth to the contract");
	});

	it('stakeFunds() should stake 2 Eth for the first 4 accounts', async () => {
		const DepositoryInstance = await Depository.deployed();
		const SaleInstance = await Sale.deployed();
		const MainTokenInstance = await MainToken.deployed();
		const amount = 0.05 * decimal;
		const amountFive = 20 * decimal;

		function timeout(ms) {
	        return new Promise(resolve => setTimeout(resolve, ms));
	    }
		
		await timeout(2000);
		await SaleInstance.buyTokens(accountOne, {from: accountOne,  value: amount.toString()})
		await SaleInstance.buyTokens(accountTwo, {from: accountTwo,  value: amount.toString()})
		await SaleInstance.buyTokens(accountThree, {from: accountThree,  value: amount.toString()})
		await SaleInstance.buyTokens(accountFive, {from: accountFive,  value: amountFive.toString()})
		await MainTokenInstance.approve(Depository.address, amount.toString())
		await MainTokenInstance.approve(Depository.address, amount.toString(), {from: accountTwo})
		await MainTokenInstance.approve(Depository.address, amount.toString(), {from: accountThree})
		await MainTokenInstance.approve(Depository.address, amountFive.toString(), {from: accountFive})
		await DepositoryInstance.stake(amount.toString(), { from: accountOne});
		await DepositoryInstance.stake(amount.toString(), { from: accountTwo});
		await DepositoryInstance.stake(amount.toString(), { from: accountThree});
		await DepositoryInstance.stake(amountFive.toString(), { from: accountFive});

		let balanceOne = await DepositoryInstance.getStakedFundsOf(accountOne);
		let balanceTwo = await DepositoryInstance.getStakedFundsOf(accountTwo);
		let balanceThree = await DepositoryInstance.getStakedFundsOf(accountThree);
		let balanceFive = await DepositoryInstance.getStakedFundsOf(accountFive);
		let totalStakedFunds = await DepositoryInstance.getTotalStakedFunds();

		assert.equal(balanceOne, amount, "accountOne not deposited 5 Eth to the contract");
		assert.equal(balanceTwo, amount, "accountTwo not deposited 5 Eth to the contract");
		assert.equal(balanceThree, amount, "accountThree not deposited 5 Eth to the contract");
		assert.equal(balanceFive, amountFive, "accountFive not deposited 5 Eth to the contract");
		assert.equal(totalStakedFunds, amount*3+amountFive, "totalStakedFunds wrong");

	});

	var hashOrder_1;

	it('placeLimitOrder() accountOne should add short $300 limit order with price $120', async () => {
		const FutureContractInstance = await FutureContract.deployed();
		const price = 120 * decimalUsd;
		const amount = 300 * decimalUsd;
		const orderType = 0;
		const leverage = 800;
		const expiresIn = 1000;

		await FutureContractInstance
			.placeLimitOrder(price.toString(), amount.toString(), orderType, leverage, expiresIn, { from: accountOne});

		let ev = await FutureContractInstance.getPastEvents( 'LimitOrderLog', { fromBlock: 0, toBlock: 'latest' } )

		let LimitOrderLog = ev[0].args;
		hashOrder_1 = LimitOrderLog.hash;
		let limitOrder = await FutureContractInstance.orders(hashOrder_1);

		assert.equal(LimitOrderLog.price, price, "LimitOrderLog, wrong price emited");
		assert.equal(LimitOrderLog.amount, amount, "LimitOrderLog, wrong amount emited");
		assert.equal(LimitOrderLog.orderType, orderType, "LimitOrderLog, wrong orderType emited");
		assert.equal(LimitOrderLog.leverage, leverage, "LimitOrderLog, wrong leverage emited");

		assert.equal(limitOrder.price, price, "limitOrder, wrong price ordered");
		assert.equal(limitOrder.amount, amount, "limitOrder, wrong amount ordered");
		assert.equal(limitOrder.orderType, orderType, "limitOrder, wrong orderType ordered");
		assert.equal(limitOrder.leverage, leverage, "limitOrder, wrong leverage ordered");
	});


	it('placeMarketOrder() accountFour should take long position $200 with price $120 and leverage 10', async () => {
		const FutureContractInstance = await FutureContract.deployed();
		const DepositoryInstance = await Depository.deployed();

		const amount = 200 * decimalUsd;
		const leverage = 1000;
		const price = 120 * decimalUsd;

		await FutureContractInstance
			.placeMarketOrder([hashOrder_1], amount.toString(), leverage, { from: accountFour });

		let ev = await FutureContractInstance.getPastEvents( 'MarketOrderLog', { fromBlock: 0, toBlock: 'latest' } )
		let MarketOrderLog = ev[0].args;
		let marketOrder = await FutureContractInstance.positions(accountFour);
		let availableBalance = await DepositoryInstance.getAvailableBalance(accountFour);
		let balance = await DepositoryInstance.getBalance (accountFour);
 		let pnlTest = calcPNL(price, currentPrice, amount, 1);
 		let positionCostTest = getCost(price, amount, leverage);
 		let availableBalanceTest = balanceAccountFour - positionCostTest;
		
		assert.equal(balance, balanceAccountFour, "Balance wrong");
		assert.equal(availableBalance.toString().slice(0,-13), availableBalanceTest.toString().slice(0,-13), "availableBalance wrong");
		assert.equal(MarketOrderLog.amount, amount, "MarketOrderLog, wrong amount emited");
		assert.equal(MarketOrderLog.positionType, 1, "MarketOrderLog, wrong positionType emited");
		assert.equal(MarketOrderLog.orderHash, hashOrder_1, "MarketOrderLog, wrong orderHash emited");
		assert.equal(marketOrder.price, price, "marketOrder, wrong price taken");
		assert.equal(marketOrder.amount, amount, "marketOrder, wrong amount taken");
		assert.equal(marketOrder.positionType, 1, "marketOrder, wrong positionType taken");
		assert.equal(marketOrder.leverage, leverage, "marketOrder, wrong leverage taken");
	});


	it('placeMarketOrder() accountFour should add to existing long position $50 with price $120 and leverage 5', async () => {
		const FutureContractInstance = await FutureContract.deployed();
		const DepositoryInstance = await Depository.deployed();
		const amount = 50 * decimalUsd;
		const leverage = 500;
		const price = 120 * decimalUsd;

		await FutureContractInstance
			.placeMarketOrder([hashOrder_1], amount.toString(), leverage, { from: accountFour });

		let ev = await FutureContractInstance.getPastEvents( 'MarketOrderLog', { fromBlock: 0, toBlock: 'latest' } )

		let MarketOrderLog = ev[1].args;
		let position = await FutureContractInstance.positions(accountFour);
		const amountSum = amount + 200 * decimalUsd; // $250
		
		// testing available balance for current price $140.
		// available balance will change depends of the current price, since pnl will be different
		let availableBalance = await DepositoryInstance.getAvailableBalance(accountFour);
		let balance = await DepositoryInstance.getBalance (accountFour);
		let positionCostTest = getCost(price, amountSum, leverage);
 		let pnlTest = calcPNL(price, currentPrice, amountSum, 1);
 		let availableBalanceTest = balanceAccountFour  - positionCostTest;

		assert.equal(availableBalance.toString().slice(0,-13), availableBalanceTest.toString().slice(0,-13), "availableBalance wrong");
		assert.equal(balance, balanceAccountFour, "Balance wrong");
		assert.equal(MarketOrderLog.amount, amount, "MarketOrderLog, wrong amount emited");
		assert.equal(MarketOrderLog.positionType, 1, "MarketOrderLog, wrong positionType emited");
		assert.equal(MarketOrderLog.orderHash, hashOrder_1, "MarketOrderLog, wrong orderHash emited");
		assert.equal(position.price, 120 * decimalUsd, "position, wrong price taken");
		assert.equal(position.amount, amountSum, "position, wrong amount taken");
		assert.equal(position.positionType, 1, "position, wrong positionType taken");
		assert.equal(position.leverage, leverage, "position, wrong leverage taken");
	});


	var hashOrder_2;

	it('placeLimitOrder() accountFour should add short $500 limit order with price $120', async () => {
		const FutureContractInstance = await FutureContract.deployed();

		const price = 100 * decimalUsd;
		const amount = 500 * decimalUsd;
		const orderType = 0;
		const leverage = 300;
		const expiresIn = 1000;

		await FutureContractInstance
			.placeLimitOrder(price.toString(), amount.toString(), orderType, leverage, expiresIn, { from: accountFour});

		let ev = await FutureContractInstance.getPastEvents( 'LimitOrderLog', { fromBlock: 0, toBlock: 'latest' } )
		let LimitOrderLog = ev[1].args;
		
		hashOrder_2 = LimitOrderLog.hash;
		let limitOrder = await FutureContractInstance.orders(hashOrder_2);

		assert.equal(LimitOrderLog.price, price, "LimitOrderLog, wrong price emited");
		assert.equal(LimitOrderLog.amount, amount, "LimitOrderLog, wrong amount emited");
		assert.equal(LimitOrderLog.orderType, orderType, "LimitOrderLog, wrong orderType emited");
		assert.equal(LimitOrderLog.leverage, leverage, "LimitOrderLog, wrong leverage emited");
		assert.equal(limitOrder.price, price, "limitOrder, wrong price ordered");
		assert.equal(limitOrder.amount, amount, "limitOrder, wrong amount ordered");
		assert.equal(limitOrder.orderType, orderType, "limitOrder, wrong orderType ordered");
		assert.equal(limitOrder.leverage, leverage, "limitOrder, wrong leverage ordered");
	});

	it('placeMarketOrder() accountThree should take long position $350 with price $100 and leverage 4', async () => {
		const FutureContractInstance = await FutureContract.deployed();
		const DepositoryInstance = await Depository.deployed();
		const amount = 350 * decimalUsd;
		const leverage = 400;
		const price = 100 * decimalUsd;

		await FutureContractInstance.placeMarketOrder([hashOrder_2], amount.toString(), leverage, { from: accountThree });

		let ev = await FutureContractInstance.getPastEvents( 'MarketOrderLog', { fromBlock: 0, toBlock: 'latest' } )
		let MarketOrderLog = ev[2].args;

		// ACCOUNT FOUR

		// At this point we have long position for accountFour, with amount $250 and price $120 
		// Since we are trying to take short position for amount $350 which is more then we have opened now 
		// we suppose to close existing long $250 position and open $100 short position ($350 - $250)

		let positionFourPrice = 120 * decimalUsd;
		let positionFourAmount = 250 * decimalUsd;
		let positionFourLeverage = 300;
		let pnlTestFour = calcPNL(positionFourPrice, price, positionFourAmount, 0);

		// we are getting negative pnl since we took position on price $120 and closing on $100 
		balanceAccountFour = balanceAccountFour - pnlTestFour[0];

		// testing available balance for current price $140.
		// available balance will change depends of the current price, since pnl will be different
		let availableBalanceFour = await DepositoryInstance.getAvailableBalance(accountFour);
		let newPositionFourAmount = amount - positionFourAmount;
 		let positionCostTestFour = getCost(price, newPositionFourAmount, positionFourLeverage);
 		let pnlTestFourCurrent = calcPNL(price, currentPrice, newPositionFourAmount, 0);
		let availableBalanceTestFour = balanceAccountFour  - positionCostTestFour;

		// testing poition state after transaction

		let balanceFour = await DepositoryInstance.getBalance (accountFour);
		position = await FutureContractInstance.positions(accountFour);
		
		assert.equal(availableBalanceFour.toString().slice(0,-13), availableBalanceTestFour.toString().slice(0,-13), "accountFour. availableBalance wrong");
		assert.equal(balanceFour.toString().slice(0,-13), balanceAccountFour.toString().slice(0,-13)	, "accountFour. Balance wrong");
		assert.equal(position.amount, newPositionFourAmount, "accountFour. Wrong position amount");
		assert.equal(position.price, price, "accountFour. Wrong position price");
		assert.equal(position.leverage, positionFourLeverage, "accountFour. Wrong position leverage");
		assert.equal(position.positionType, 0, "accountFour. Wrong position positionType");

		// ACCOUNT THREE

		let positionThree = await FutureContractInstance.positions(accountThree);
		let availableBalanceThree = await DepositoryInstance.getAvailableBalance(accountThree);
		let balanceThree = await DepositoryInstance.getBalance (accountThree);
 		let pnlTestThree = calcPNL(price, currentPrice, amount, 1);
 		let positionCostTestThree = getCost(price, amount, leverage);
 		let availableBalanceTestThree = balanceAccountThree  - positionCostTestThree;

		assert.equal(balanceThree, balanceAccountThree, "accountThree. Balance wrong");
		assert.equal(availableBalanceThree.toString().slice(0,-13), availableBalanceTestThree.toString().slice(0,-13), "accountThree. availableBalance wrong");
		assert.equal(MarketOrderLog.amount, amount, "accountThree. MarketOrderLog, wrong amount emited");
		assert.equal(MarketOrderLog.positionType, 1, "accountThree. MarketOrderLog, wrong positionType emited");
		assert.equal(MarketOrderLog.orderHash, hashOrder_2, "accountThree. MarketOrderLog, wrong orderHash emited");
		assert.equal(positionThree.price, price, "accountThree. positionThree, wrong price taken");
		assert.equal(positionThree.amount, amount, "accountThree. positionThree, wrong amount taken");
		assert.equal(positionThree.positionType, 1, "accountThree. positionThree, wrong positionType taken");
		assert.equal(positionThree.leverage, leverage, "accountThree. positionThree, wrong leverage taken");
	});

	var hashOrder_3;
	it('placeLimitOrder() accountTwo should add short $600 limit order with price $90', async () => {
		const FutureContractInstance = await FutureContract.deployed();
		const price = 90 * decimalUsd;
		const amount = 600 * decimalUsd;
		const orderType = 0;
		const leverage = 700;
		const expiresIn = 1000;

		await FutureContractInstance
			.placeLimitOrder(price.toString(), amount.toString(), orderType, leverage, expiresIn, { from: accountTwo});

		let ev = await FutureContractInstance.getPastEvents( 'LimitOrderLog', { fromBlock: 0, toBlock: 'latest' } )
		let LimitOrderLog = ev[2].args;
		
		hashOrder_3 = LimitOrderLog.hash;
		let limitOrder = await FutureContractInstance.orders(hashOrder_3);

		assert.equal(LimitOrderLog.price, price, "LimitOrderLog, wrong price emited");
		assert.equal(LimitOrderLog.amount, amount, "LimitOrderLog, wrong amount emited");
		assert.equal(LimitOrderLog.orderType, orderType, "LimitOrderLog, wrong orderType emited");
		assert.equal(LimitOrderLog.leverage, leverage, "LimitOrderLog, wrong leverage emited");
		assert.equal(limitOrder.price, price, "limitOrder, wrong price ordered");
		assert.equal(limitOrder.amount, amount, "limitOrder, wrong amount ordered");
		assert.equal(limitOrder.orderType, orderType, "limitOrder, wrong orderType ordered");
		assert.equal(limitOrder.leverage, leverage, "limitOrder, wrong leverage ordered");
	});

	it('placeMarketOrder() accountFour should add to existing long position $30 with price $90 and leverage 6', async () => {
		const FutureContractInstance = await FutureContract.deployed();
		const DepositoryInstance = await Depository.deployed();
		const amount = 30 * decimalUsd;
		const leverage = 600;
		const price = 90 * decimalUsd;

		await FutureContractInstance
			.placeMarketOrder([hashOrder_3], amount.toString(), leverage, { from: accountFour });

		let ev = await FutureContractInstance.getPastEvents( 'MarketOrderLog', { fromBlock: 0, toBlock: 'latest' } );
		let MarketOrderLog = ev[3].args;
		let positionFour = await FutureContractInstance.positions(accountFour);

		//ACCOUNT FOUR

		const positionAmountFour = 100 * decimalUsd;
		const positionPriceFour = 100 * decimalUsd;
		const amountRes = 100 * decimalUsd - amount;

		// We have $100 short position with $100 price, now we are getting $30 a long position with $90 price
	
		let availableBalance = await DepositoryInstance.getAvailableBalance(accountFour);
		let balance = await DepositoryInstance.getBalance (accountFour);

		// check PNL of closing position 
		let pnlTestFour = calcPNL(positionPriceFour, price, amount, 0);
		balanceAccountFour = balanceAccountFour + pnlTestFour[0];

		let positionCostTest = getCost(positionPriceFour, amountRes, leverage);
 		let pnlTest = calcPNL(positionPriceFour, currentPrice, amountRes, 0);
 		let availableBalanceTest = balanceAccountFour - positionCostTest;

		assert.equal(availableBalance.toString().slice(0,-13), availableBalanceTest.toString().slice(0,-13), "accountFour. availableBalance wrong");
		assert.equal(balance.toString().slice(0,-13), balanceAccountFour.toString().slice(0,-13), "accountFour. Balance wrong");
		assert.equal(MarketOrderLog.amount, amount, "accountFour. MarketOrderLog, wrong amount emited");
		assert.equal(MarketOrderLog.positionType, 1, "accountFour. MarketOrderLog, wrong positionType emited");
		assert.equal(MarketOrderLog.orderHash, hashOrder_3, "accountFour. MarketOrderLog, wrong orderHash emited");
		assert.equal(positionFour.price, positionPriceFour, "accountFour. position, wrong price taken");
		assert.equal(positionFour.amount, amountRes, "accountFour. position, wrong amount taken");
		assert.equal(positionFour.positionType, 0, "accountFour. position, wrong positionType taken");
		assert.equal(positionFour.leverage, leverage, "accountFour. position, wrong leverage taken");

		//ACCOUNT TWO
		
		let positionTwo = await FutureContractInstance.positions(accountTwo);
		assert.equal(positionTwo.amount, amount, "accountTwo. position, wrong amount taken");
		assert.equal(positionTwo.positionType, 0, "accountTwo. position, wrong positionType taken");
		assert.equal(positionTwo.leverage, 700, "accountTwo. position, wrong leverage taken");
	});

	var hashOrder_4;
	it('placeLimitOrder() accountThree should add long $200 limit order with price $130', async () => {

		const FutureContractInstance = await FutureContract.deployed();
		const price = 130 * decimalUsd;
		const amount = 200 * decimalUsd;
		const orderType = 1;
		const leverage = 200;
		const expiresIn = 1000;

		await FutureContractInstance
			.placeLimitOrder(price.toString(), amount.toString(), orderType, leverage, expiresIn, { from: accountThree});

		let ev = await FutureContractInstance.getPastEvents( 'LimitOrderLog', { fromBlock: 0, toBlock: 'latest' } )
		let LimitOrderLog = ev[3].args;
		
		hashOrder_4 = LimitOrderLog.hash;
		let limitOrder = await FutureContractInstance.orders(hashOrder_4);

		assert.equal(LimitOrderLog.price, price, "LimitOrderLog, wrong price emited");
		assert.equal(LimitOrderLog.amount, amount, "LimitOrderLog, wrong amount emited");
		assert.equal(LimitOrderLog.orderType, orderType, "LimitOrderLog, wrong orderType emited");
		assert.equal(LimitOrderLog.leverage, leverage, "LimitOrderLog, wrong leverage emited");
		assert.equal(limitOrder.price, price, "limitOrder, wrong price ordered");
		assert.equal(limitOrder.amount, amount, "limitOrder, wrong amount ordered");
		assert.equal(limitOrder.orderType, orderType, "limitOrder, wrong orderType ordered");
		assert.equal(limitOrder.leverage, leverage, "limitOrder, wrong leverage ordered");
	});


	it('placeMarketOrder() accountFour should add to existing short position $80 with price $90 and leverage 3.5', async () => {
		
		const FutureContractInstance = await FutureContract.deployed();
		const DepositoryInstance = await Depository.deployed();
		const amount = 80 * decimalUsd;
		const leverage = 350;
		const price = 130 * decimalUsd;

		let positionThreeBefore = await FutureContractInstance.positions(accountThree);

		await FutureContractInstance
			.placeMarketOrder([hashOrder_4], amount.toString(), leverage, { from: accountFour });

		let ev = await FutureContractInstance.getPastEvents( 'MarketOrderLog', { fromBlock: 0, toBlock: 'latest' } );
		let MarketOrderLog = ev[4].args;
		let positionFour = await FutureContractInstance.positions(accountFour);

		// We have a short $70 position with $100 price, now we are adding $80 a short position with $130 price
		// means that price should be changed to average.
		let positionPriceFour = calcPrice(100 * decimalUsd, 70*decimalUsd, price, amount);
		positionPriceFour = Math.floor(positionPriceFour);
		const amountRes = 70 * decimalUsd + amount;

		//ACCOUNT FOUR

		let availableBalance = await DepositoryInstance.getAvailableBalance(accountFour);
		let balance = await DepositoryInstance.getBalance (accountFour);

		// check PNL of closing position 
		let pnlTestFour = calcPNL(positionPriceFour, price, amount, 0);
		let positionCostTest = getCost(positionPriceFour, amountRes, leverage);
 		let pnlTest = calcPNL(positionPriceFour, currentPrice, amountRes, 0);
 		let availableBalanceTest = balanceAccountFour  - positionCostTest;

		assert.equal(availableBalance.toString().slice(0,-13), availableBalanceTest.toString().slice(0,-13), "accountFour. availableBalance wrong");
		assert.equal(balance.toString().slice(0,-13), balanceAccountFour.toString().slice(0,-13), "accountFour. Balance wrong");
		assert.equal(MarketOrderLog.amount, amount, "accountFour. MarketOrderLog, wrong amount emited");
		assert.equal(MarketOrderLog.positionType, 0, "accountFour. MarketOrderLog, wrong positionType emited");
		assert.equal(MarketOrderLog.orderHash, hashOrder_4, "accountFour. MarketOrderLog, wrong orderHash emited");
		assert.equal(positionFour.price, positionPriceFour, "accountFour. position, wrong price taken");
		assert.equal(positionFour.amount, amountRes, "accountFour. position, wrong amount taken");
		assert.equal(positionFour.positionType, 0, "accountFour. position, wrong positionType taken");
		assert.equal(positionFour.leverage, leverage, "accountFour. position, wrong leverage taken");

		//ACCOUNT THREE

		let positionThree = await FutureContractInstance.positions(accountThree);
		let positionPriceThree = calcPrice(positionThreeBefore.price.toNumber(), positionThreeBefore.amount.toNumber(), price, amount);

		assert.equal(positionThree.price, Math.floor(positionPriceThree), "accountThree. positionThree, wrong price taken");
		assert.equal(positionThree.amount, positionThreeBefore.amount.toNumber() + amount, "accountThree. positionThree, wrong amount taken");
		assert.equal(positionThree.positionType, 1, "accountThree. positionThree, wrong positionType taken");
		assert.equal(positionThree.leverage, 200, "accountThree. positionThree, wrong leverage taken");		
	});

	it('requestToChangeFeeLimit() should create request for change limit orders fee from 0 to 30, which means 0.3% times on 100', async () => {
		const SettingsInstance = await Settings.deployed();
		await SettingsInstance.requestToChangeFeeLimit(30, { from: accountOne });
		let feeLimitOrder = await SettingsInstance.requestedToChangeFeeLimitOrder();
		assert.equal(feeLimitOrder, 30, "Wrong limit order fee ");	
	});


	it('changeFeeLimit() should change limit orders fee', async () => {
		const SettingsInstance = await Settings.deployed();
		await SettingsInstance.changeFeeLimit({ from: accountOne });
		let feeLimitOrder = await SettingsInstance.getFeeLimitOrder();
		assert.equal(feeLimitOrder, 30, "Wrong limit order fee ");	
	});

	it('requestToChangeFeeMarket() should create request for change market orders fee from 0 to 50, which means 0.5% multiplyed on 100', async () => {
		const SettingsInstance = await Settings.deployed();
		await SettingsInstance.requestToChangeFeeMarket(50, { from: accountOne });
		let feeMarketOrder = await SettingsInstance.requestedToChangeFeeMarketOrder();
		assert.equal(feeMarketOrder, 50, "Wrong market order fee ");	
	});

	it('changeFeeMarket() should change market orders fee', async () => {
		const SettingsInstance = await Settings.deployed();
		await SettingsInstance.changeFeeMarket({ from: accountOne });
		let feeMarketOrder = await SettingsInstance.getFeeMarketOrder();
		assert.equal(feeMarketOrder, 50, "Wrong market order fee ");	
	});


	var hashOrder_5;
	it('placeLimitOrder() accountThree should add long $200 limit order with price $130 with new fees', async () => {
		const FutureContractInstance = await FutureContract.deployed();
		const price = 130 * decimalUsd;
		const amount = 200 * decimalUsd;
		const orderType = 1;
		const leverage = 200;
		const expiresIn = 1000;

		await FutureContractInstance
			.placeLimitOrder(price.toString(), amount.toString(), orderType, leverage, expiresIn, { from: accountThree});

		let ev = await FutureContractInstance.getPastEvents( 'LimitOrderLog', { fromBlock: 0, toBlock: 'latest' } )

		let LimitOrderLog = ev[3].args;
		
		hashOrder_5 = LimitOrderLog.hash;
		let limitOrder = await FutureContractInstance.orders(hashOrder_5);

		assert.equal(LimitOrderLog.price, price, "LimitOrderLog, wrong price emited");
		assert.equal(LimitOrderLog.amount, amount, "LimitOrderLog, wrong amount emited");
		assert.equal(LimitOrderLog.orderType, orderType, "LimitOrderLog, wrong orderType emited");
		assert.equal(LimitOrderLog.leverage, leverage, "LimitOrderLog, wrong leverage emited");

		assert.equal(limitOrder.price, price, "limitOrder, wrong price ordered");
		assert.equal(limitOrder.amount, amount, "limitOrder, wrong amount ordered");
		assert.equal(limitOrder.orderType, orderType, "limitOrder, wrong orderType ordered");
		assert.equal(limitOrder.leverage, leverage, "limitOrder, wrong leverage ordered");
	});


	it('placeMarketOrder() accountFour should add to existing short position $80 with price $90 and leverage 3.5 with new fees', async () => {
		
		const FutureContractInstance = await FutureContract.deployed();
		const DepositoryInstance = await Depository.deployed();
		const SettingsInstance = await Settings.deployed();
		const TokenInstance = await Token.deployed();



		const amount = 80 * decimalUsd;
		const leverage = 350;
		const price = 130 * decimalUsd;

		let positionThreeBefore = await FutureContractInstance.positions(accountThree);
		let positionFourBefore = await FutureContractInstance.positions(accountFour);

		await FutureContractInstance
			.placeMarketOrder([hashOrder_5], amount.toString(), leverage, { from: accountFour });

		let ev = await FutureContractInstance.getPastEvents( 'MarketOrderLog', { fromBlock: 0, toBlock: 'latest' } );
		let MarketOrderLog = ev[4].args;
		let positionFour = await FutureContractInstance.positions(accountFour);
		let positionPriceFour = calcPrice(100 * decimalUsd, positionFourBefore.amount, price, amount);
		positionPriceFour = Math.floor(positionPriceFour);

		const amountRes = positionFourBefore.amount + amount;

		//ACCOUNT FOUR

		let balanceFour = await DepositoryInstance.getBalance (accountFour);
		let feeMarketOrder = await SettingsInstance.getFeeMarketOrder(); 
		let feeValueFour = getCost(price, amount, leverage)*feeMarketOrder/10000;
		

		//calc discount 

		let accountTokenBalance = await TokenInstance.balanceOf(accountFour);
		let tokenTotalSupply = await TokenInstance.totalSupply();
		let DiscountFeePercentTest = 0;
		let feeDiscountIndex = 100;
		if (tokenTotalSupply>0) DiscountFeePercentTest = accountTokenBalance * 100 * percentMultiplyer * feeDiscountIndex / tokenTotalSupply;
        if(feeValueFour==0 || DiscountFeePercentTest >= 100 * percentMultiplyer) {
        	DiscountFeePercentTest = 10000;
        }

		let discountFeePercent = await DepositoryInstance.calcDiscountFeePercent(accountFour, Math.floor(feeValueFour));
		let feeValueWithDiscount = await DepositoryInstance.calcFeeValueWithDiscount(discountFeePercent, Math.floor(feeValueFour));

		balanceAccountFour = balanceAccountFour - feeValueWithDiscount;

		let discountPercentTest = 5000;
		let feeValueWithDiscountTest = await DepositoryInstance.calcFeeValueWithDiscount(discountPercentTest, Math.floor(feeValueFour));

 		assert.equal(discountFeePercent, DiscountFeePercentTest, "accountFour. calcDiscountFeePercent() wrong");
 		assert.equal(feeValueWithDiscount, 0, "accountFour. calcFeeValueWithDiscount() wrong");
		assert.equal(balanceFour.toString().slice(0,-14), balanceAccountFour.toString().slice(0,-14), "accountFour. Balance wrong");
		assert.equal(MarketOrderLog.amount, amount, "accountFour. MarketOrderLog, wrong amount emited");
		assert.equal(MarketOrderLog.positionType, 0, "accountFour. MarketOrderLog, wrong positionType emited");
		assert.equal(MarketOrderLog.orderHash, hashOrder_5, "accountFour. MarketOrderLog, wrong orderHash emited");
		assert.equal(positionFour.price, 119123505975, "accountFour. position, wrong price taken");
		assert.equal(positionFour.amount, 230000000000, "accountFour. position, wrong amount taken");
		assert.equal(positionFour.positionType, 0, "accountFour. position, wrong positionType taken");
		assert.equal(positionFour.leverage, leverage, "accountFour. position, wrong leverage taken");
		assert.equal(feeValueWithDiscountTest, 439560439560439, "accountFour. calcFeeValueWithDiscount() 5000 wrong");


		//ACCOUNT THREE


		let positionThree = await FutureContractInstance.positions(accountThree);
		let positionPriceThree = calcPrice(positionThreeBefore.price.toNumber(), positionThreeBefore.amount.toNumber(), price, amount);

		assert.equal(positionThree.price, Math.floor(positionPriceThree), "accountThree. positionThree, wrong price taken");
		assert.equal(positionThree.amount, positionThreeBefore.amount.toNumber() + amount, "accountThree. positionThree, wrong amount taken");
		assert.equal(positionThree.positionType, 1, "accountThree. positionThree, wrong positionType taken");
		assert.equal(positionThree.leverage, 200, "accountThree. positionThree, wrong leverage taken");		

		let balanceThree = await DepositoryInstance.getBalance (accountThree);
		let feeLimitOrder = await SettingsInstance.getFeeLimitOrder(); 
		let submitCost = getCost(price, amount, 200);
		let feeValueThree = submitCost * feeLimitOrder / 10000;

		let discountFeePercentThree = await DepositoryInstance.calcDiscountFeePercent(accountThree, Math.floor(feeValueThree));
		let feeValueWithDiscountThree = await DepositoryInstance.calcFeeValueWithDiscount(discountFeePercentThree, Math.floor(feeValueThree));

		balanceAccountThree = balanceAccountThree - feeValueThree;
		assert.equal(balanceThree.toString().slice(0,-14), balanceAccountThree.toString().slice(0,-14), "accountThree. Balance wrong");

		let allTimeTotalProfit = await DepositoryInstance.allTimeTotalProfit();
		let marginBank = await DepositoryInstance.marginBank();
		let totalProfitTest = Math.floor(feeValueThree+feeValueWithDiscount);

		assert.equal(allTimeTotalProfit, totalProfitTest, "allTimeTotalProfit wrong");
		assert.equal(discountFeePercentThree, 0, "discountFeePercentThree wrong");
		assert.equal(feeValueWithDiscountThree, Math.floor(feeValueThree), "feeValueWithDiscountThree wrong");

	});

	it('liquidatePosition() accountOne', async () => {
		const FutureContractInstance = await FutureContract.deployed();
		await FutureContractInstance.liquidatePosition(accountOne);
		let positionOne = await FutureContractInstance.positions(accountOne);
		assert.equal(positionOne.price, 0, "position price wrong");
		assert.equal(positionOne.amount, 0, "position amount wrong");
		assert.equal(positionOne.leverage, 0, "position leverage wrong");
	});

	it('expirationTest() accountFour', async () => {
		const DepositoryInstance = await Depository.deployed();
		const FutureContractInstance = await FutureContract.deployed();

		let balanceFourBefore = await DepositoryInstance.getBalance(accountFour);
		let positionFourBefore = await FutureContractInstance.positions(accountFour);
		let pnlFour = calcPNL(positionFourBefore.price.toNumber(), 140*decimalUsd, positionFourBefore.amount.toNumber(), 0);
		let balanceFourTest = balanceFourBefore*1 - pnlFour[0] ;

		await FutureContractInstance.expirationTest({ from: accountFour });

		let balanceFour = await DepositoryInstance.getBalance(accountFour);
		let positionFour = await FutureContractInstance.positions(accountFour);

		assert.equal(balanceFour.toString().slice(0,-13), balanceFourTest.toString().slice(0,-13), "Wrong balance");
		assert.equal(positionFour.price, 0, "position amount wrong");
		assert.equal(positionFour.amount, 0, "position amount wrong");
		assert.equal(positionFour.leverage, 0, "position leverage wrong");
	});

	it('expirationTest() accountThree', async () => {
		const DepositoryInstance = await Depository.deployed();
		const FutureContractInstance = await FutureContract.deployed();
		const TokenContractInstance = await Token.deployed();
		
		let balanceThreeBefore = await DepositoryInstance.getBalance(accountThree);
		let positionFourBefore = await FutureContractInstance.positions(accountThree);
		let pnlFour = calcPNL(positionFourBefore.price.toNumber(), 140*decimalUsd, positionFourBefore.amount.toNumber(), 0);
		let balanceThreeTest = balanceThreeBefore*1 + pnlFour[0] ;
		let totalBalanceBefore = await DepositoryInstance.totalBalance();
		let contractBalance = await DepositoryInstance.getWalletBalance(Depository.address);
		let allTimeTotalProfit = await DepositoryInstance.allTimeTotalProfit();

		await FutureContractInstance.expirationTest({ from: accountThree });
		
		let marginBank = await DepositoryInstance.marginBank();
		let newTotalBalance = totalBalanceBefore*1 + balanceThreeTest.toString()*1 - balanceThreeBefore.toString()*1;
		let availableTotalBalance = contractBalance - allTimeTotalProfit - marginBank - 11537500000000000;
		let diff = newTotalBalance.toString()*1 - availableTotalBalance.toString()*1;
		
		balanceThreeTest = balanceThreeTest.toString()*1 - diff;

		let balanceThree = await DepositoryInstance.getBalance(accountThree);
		let totalBalance = await DepositoryInstance.totalBalance();

		assert.equal(balanceThree.toString().slice(0,-7), balanceThreeTest.toString().slice(0,-7), "Wrong balance");
		assert.equal(totalBalance.toString().slice(0,-7), availableTotalBalance.toString().slice(0,-7), "Wrong totalBalance");
		
		let positionFour = await FutureContractInstance.positions(accountThree);
		assert.equal(positionFour.price, 0, "position amount wrong");
		assert.equal(positionFour.amount, 0, "position amount wrong");
		assert.equal(positionFour.leverage, 0, "position leverage wrong");
	});


	it('tokenBalanceOf() accountFour', async () => {
		const DepositoryInstance = await Depository.deployed();
		const TokenInstance = await Token.deployed();
		let balance = await TokenInstance.balanceOf(accountFour);
		assert.equal(balance, 704578680000000000, "position amount wrong");
	});

	
	it('getAccountStakePercent() accountFive', async () => {
		const DepositoryInstance = await Depository.deployed();
		let accountStakePercent = await DepositoryInstance.getAccountStakePercent(accountFive);
		let totalStakedTest = 20+3*0.05;
		let percentStakedTest = Math.floor(20*100*100/totalStakedTest);
		assert.equal(accountStakePercent, percentStakedTest, "accountStakePercent wrong");
	});
	
	it('calcAccountProfit() accountFive', async () => {
		const DepositoryInstance = await Depository.deployed();
		let accountStakePercent = await DepositoryInstance.getAccountStakePercent(accountFive);
		let allTimeTotalProfit = await DepositoryInstance.allTimeTotalProfit(); 
		let stakedFundsAmount = await DepositoryInstance.getStakedFundsOf(accountFive);
		let prevAllTimeProfit = await DepositoryInstance.getPrevAllTimeProfit(accountFive);
		let unreleasedProfit = allTimeTotalProfit.toString()*1 - prevAllTimeProfit.toString()*1;
		let accountProfitTest = unreleasedProfit.toString()*1 * accountStakePercent.toString()*1 / 10000;
		let accountProfit = await DepositoryInstance.calcAccountProfit({ from: accountFive });
		assert.equal(accountProfit, accountProfitTest, "accountProfit wrong");
	});


	it('getDividends() accountFive', async () => {
		const DepositoryInstance = await Depository.deployed();

		let walletBalanceBefore = await DepositoryInstance.getWalletBalance(accountFive);
		let accountProfit = await DepositoryInstance.calcAccountProfit({ from: accountFive });
		let walletBalanceAfterTest = walletBalanceBefore.toString()*1 + accountProfit.toString()*1 - 12367122600558600;
		let walletBalanceAfter = await DepositoryInstance.getWalletBalance(accountFive);
		assert.equal( Math.floor(walletBalanceAfter.toString()*1/decimalUsd), Math.floor(walletBalanceAfterTest/decimalUsd), "walletBalanceFive. Wallet balance wrong");

	});

	
	it('unstakeFunds. accountFive', async () => {
		const DepositoryInstance = await Depository.deployed();
		const SettingsInstance = await Settings.deployed();
		const MainTokenInstance = await MainToken.deployed();

		let stakedFundsBefore = await DepositoryInstance.getStakedFundsOf(accountFive);
		let totalStakedFundsBefore = await DepositoryInstance.getTotalStakedFunds();
		//let balanceTokenBefore  = await MainTokenInstance.balanceOf(accountFive)

		await DepositoryInstance.unstake(stakedFundsBefore.toString(), { from: accountFive });

		let stakedFundsAfter = await DepositoryInstance.getStakedFundsOf(accountFive);
		let totalStakedFundsAfter = await DepositoryInstance.getTotalStakedFunds();
		//let   = await MainTokenInstance.balanceOf(accountFive)

		assert.equal(stakedFundsAfter.toString()*1, 0, "accountFive. Stake funds are wrong");
		assert.equal(totalStakedFundsAfter.toString()*1, totalStakedFundsBefore.toString()*1 - stakedFundsBefore.toString()*1, "accountFive. Total staked funds are wrong");

	});
	
	
	it('redeploy future contract', async () => {
		const FutureContractInstance = await FutureContract.deployed();
		const SettingsInstance = await Settings.deployed();
		let redeployedAddress = await FutureContractInstance.redeployedAddress();
		let isContractTrusted = await SettingsInstance.isContractTrusted(redeployedAddress);
		assert.isBoolean(isContractTrusted, "Redeployed Contract Is Not Trasted");
	});


	it('Meta', async () => {
		const MetaInstance = await Meta.deployed();

		let name = await MetaInstance.name();
		let description = await MetaInstance.description();
		let author = await MetaInstance.author();

		let urlWebVersion = await MetaInstance.urlWebVersion();
		let urlDownloadVersion = await MetaInstance.urlDownloadVersion();
		let urlMobileVersion = await MetaInstance.urlMobileVersion();
		let depositoryAddress = await MetaInstance.depositoryAddress();
		let settingsAddress = await MetaInstance.settingsAddress();
		let contractToken = await MetaInstance.contractToken();


	});


	it('Sale. Send Ether. Each block user will get smaller amount of tokens', async () => {
		const SaleInstance = await Sale.deployed();
		const MainTokenInstance = await MainToken.deployed();
		let one_eth = 1000000000000000000;

		function timeout(ms) {
	        return new Promise(resolve => setTimeout(resolve, ms));
	    }

		await SaleInstance.buyTokens(accountOne, {from: accountOne,  value: one_eth.toString()})

		let balanceOfOne  = await MainTokenInstance.balanceOf(accountOne)
		let CurrentRate  = await SaleInstance.getCurrentRate()
	    await timeout(3000);

	    await SaleInstance.buyTokens(accountTwo, {from: accountTwo,  value: one_eth.toString()})
		CurrentRate  = await SaleInstance.getCurrentRate()
		let balanceOfTwo  = await MainTokenInstance.balanceOf(accountTwo)
		assert.isAbove(balanceOfOne.toString()*1, balanceOfTwo.toString()*1, 'balanceOfOne is strictly greater than balanceOfTwo');
		await timeout(3000);

		await SaleInstance.buyTokens(accountThree, {from: accountThree,  value: one_eth.toString()})
		CurrentRate  = await SaleInstance.getCurrentRate()
		let balanceOfThree  = await MainTokenInstance.balanceOf(accountThree)
		assert.isAbove(balanceOfTwo.toString()*1, balanceOfThree.toString()*1, 'balanceOfTwo is strictly greater than balanceOfThree');
	    await timeout(3000);

		await SaleInstance.buyTokens(accountFour, {from: accountFour,  value: one_eth.toString()})
		CurrentRate  = await SaleInstance.getCurrentRate()
		let balanceOfFour  = await MainTokenInstance.balanceOf(accountFour)
		assert.isAbove(balanceOfThree.toString()*1, balanceOfFour.toString()*1, 'balanceOfThree is strictly greater than balanceOfFour');

	});



});




///////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////


function mul(val1, val2) {
    return val1 * val2;
}

function sum(val1, val2) {
    return val1 + val2;
}

function sub(val1, val2) {
    return val1 - val2;
}

function div(val1, val2) {
    return val1 / val2;
}



function calcPNL(initialPrice, currentPrice, amount, positionType) {

    if (positionType == 1) {

        if (initialPrice <= currentPrice) {
            var pnl = mul(sub(div(1*decimal, initialPrice), div(1*decimal, currentPrice)), amount);
            return [pnl, true];
        } else {
            var pnl = mul(sub(div(1*decimal, currentPrice), div(1*decimal, initialPrice)), amount);
            return [pnl, false];
        }

    }

    if (positionType == 0) {

        if (initialPrice >= currentPrice) {
            var pnl = mul(sub(div(1*decimal, currentPrice), div(1*decimal, initialPrice)), amount);
            return [pnl, true];
        } else {
            var pnl = mul(sub(div(1*decimal, initialPrice), div(1*decimal, currentPrice)), amount);
            return [pnl, false];
        }

    }

    return false;
}


function getCost(price, amount, leverage) {
    return  Math.trunc(div(div(amount*100, price)*decimal,leverage));
}

function calcPrice(initPrice, initAmount, price, amount){

    let div1 = div(initAmount*decimal,initPrice);
    let div2 = div(amount*decimal, price);
    let sum1 = sum(initAmount, amount);  
    let sum2 = sum(div2, div1);
    return div(sum1*decimal, sum2);
    
}
