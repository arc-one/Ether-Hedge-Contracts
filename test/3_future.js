const truffleAssert = require('truffle-assertions');
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

contract('3_Future', (accounts) => {

	const accountOne = accounts[0];
	const accountTwo = accounts[1];
	const accountThree = accounts[2];
	const accountFour = accounts[3];
	const accountFive = accounts[4];

	var balanceAccountOne = 0;
	var balanceAccountTwo = 0;
	var balanceAccountThree = 0;
	var balanceAccountFour = 0;

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
	    await timeout(1000);

	    await SaleInstance.buyTokens(accountTwo, {from: accountTwo,  value: one_eth.toString()})
		CurrentRate  = await SaleInstance.getCurrentRate()
		let balanceOfTwo  = await MainTokenInstance.balanceOf(accountTwo)
		assert.isAbove(balanceOfOne.toString()*1, balanceOfTwo.toString()*1, 'balanceOfOne is strictly greater than balanceOfTwo');
		await timeout(1000);

		await SaleInstance.buyTokens(accountThree, {from: accountThree,  value: one_eth.toString()})
		CurrentRate  = await SaleInstance.getCurrentRate()
		let balanceOfThree  = await MainTokenInstance.balanceOf(accountThree)
		assert.isAbove(balanceOfTwo.toString()*1, balanceOfThree.toString()*1, 'balanceOfTwo is strictly greater than balanceOfThree');
	    await timeout(1000);

		await SaleInstance.buyTokens(accountFour, {from: accountFour,  value: one_eth.toString()})
		CurrentRate  = await SaleInstance.getCurrentRate()
		let balanceOfFour  = await MainTokenInstance.balanceOf(accountFour)
		assert.isAbove(balanceOfThree.toString()*1, balanceOfFour.toString()*1, 'balanceOfThree is strictly greater than balanceOfFour');

	});

	it('stakeFunds()', async () => {
		const DepositoryInstance = await Depository.deployed();
		const SaleInstance = await Sale.deployed();
		const MainTokenInstance = await MainToken.deployed();
		const amount = 0.05 * decimal;

		await MainTokenInstance.approve(Depository.address, amount.toString())
		await MainTokenInstance.approve(Depository.address, amount.toString(), {from: accountTwo})
		await MainTokenInstance.approve(Depository.address, amount.toString(), {from: accountThree})

		await DepositoryInstance.stake(amount.toString(), { from: accountOne});
		await DepositoryInstance.stake(amount.toString(), { from: accountTwo});
		await DepositoryInstance.stake(amount.toString(), { from: accountThree});

		let balanceOne = await DepositoryInstance.getStakedFundsOf(accountOne);
		let balanceTwo = await DepositoryInstance.getStakedFundsOf(accountTwo);
		let balanceThree = await DepositoryInstance.getStakedFundsOf(accountThree);
		let totalStakedFunds = await DepositoryInstance.getTotalStakedFunds();

		assert.equal(balanceOne, amount, "accountOne not deposited 0.05 Eth to the contract");
		assert.equal(balanceTwo, amount, "accountTwo not deposited 0.05 Eth to the contract");
		assert.equal(balanceThree, amount, "accountThree not deposited 0.05 Eth to the contract");
		assert.equal(totalStakedFunds, amount*3, "totalStakedFunds fail");

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

	it('getAvailableBalance() should return 5 ETH', async () => {
		const DepositoryInstance = await Depository.deployed();
		const amount = 5 * decimal;
		
		balanceAccountOne = amount;
		balanceAccountTwo = amount;
		balanceAccountThree = amount;
		balanceAccountFour = amount;
		

		let availableBalanceOne = await DepositoryInstance.getAvailableBalance(accountOne);
		let availableBalanceTwo = await DepositoryInstance.getAvailableBalance(accountTwo);
		let availableBalanceThree = await DepositoryInstance.getAvailableBalance(accountThree);
		let availableBalanceFour = await DepositoryInstance.getAvailableBalance(accountFour);
		
		assert.equal(availableBalanceOne, amount, "accountOne not deposited 5 Eth to the contract");
		assert.equal(availableBalanceTwo, amount, "accountTwo not deposited 5 Eth to the contract");
		assert.equal(availableBalanceThree, amount, "accountThree not deposited 5 Eth to the contract");
		assert.equal(availableBalanceFour, amount, "accountFour not deposited 5 Eth to the contract");
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

		assert.equal(LimitOrderLog.price, price, "LimitOrderLog, fail price emited");
		assert.equal(LimitOrderLog.amount, amount, "LimitOrderLog, fail amount emited");
		assert.equal(LimitOrderLog.orderType, orderType, "LimitOrderLog, fail orderType emited");
		assert.equal(LimitOrderLog.leverage, leverage, "LimitOrderLog, fail leverage emited");

		assert.equal(limitOrder.price, price, "limitOrder, fail price ordered");
		assert.equal(limitOrder.amount, amount, "limitOrder, fail amount ordered");
		assert.equal(limitOrder.orderType, orderType, "limitOrder, fail orderType ordered");
		assert.equal(limitOrder.leverage, leverage, "limitOrder, fail leverage ordered");
	});


	it('getAvailableBalance() should return 5 ETH', async () => {
		const DepositoryInstance = await Depository.deployed();
		const amount = 5 * decimal;
		
		balanceAccountOne = amount;
		balanceAccountTwo = amount;
		balanceAccountThree = amount;
		balanceAccountFour = amount;
		

		let availableBalanceOne = await DepositoryInstance.getAvailableBalance(accountOne);
		let availableBalanceTwo = await DepositoryInstance.getAvailableBalance(accountTwo);
		let availableBalanceThree = await DepositoryInstance.getAvailableBalance(accountThree);
		let availableBalanceFour = await DepositoryInstance.getAvailableBalance(accountFour);
		
		assert.equal(availableBalanceOne, amount, "accountOne not deposited 5 Eth to the contract");
		assert.equal(availableBalanceTwo, amount, "accountTwo not deposited 5 Eth to the contract");
		assert.equal(availableBalanceThree, amount, "accountThree not deposited 5 Eth to the contract");
		assert.equal(availableBalanceFour, amount, "accountFour not deposited 5 Eth to the contract");
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
		
		assert.equal(balance, balanceAccountFour, "Balance fail");
		assert.equal(availableBalance.toString().slice(0,-4), availableBalanceTest.toString().slice(0,-4), "availableBalance fail");
		assert.equal(MarketOrderLog.amount, amount, "MarketOrderLog, fail amount emited");
		assert.equal(MarketOrderLog.positionType, 1, "MarketOrderLog, fail positionType emited");
		assert.equal(MarketOrderLog.orderHash, hashOrder_1, "MarketOrderLog, fail orderHash emited");
		assert.equal(marketOrder.price, price, "marketOrder, fail price taken");
		assert.equal(marketOrder.amount, amount, "marketOrder, fail amount taken");
		assert.equal(marketOrder.positionType, 1, "marketOrder, fail positionType taken");
		assert.equal(marketOrder.leverage, leverage, "marketOrder, fail leverage taken");
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

		assert.equal(availableBalance.toString().slice(0,-4), availableBalanceTest.toString().slice(0,-4), "availableBalance fail");
		assert.equal(balance, balanceAccountFour, "Balance fail");
		assert.equal(MarketOrderLog.amount, amount, "MarketOrderLog, fail amount emited");
		assert.equal(MarketOrderLog.positionType, 1, "MarketOrderLog, fail positionType emited");
		assert.equal(MarketOrderLog.orderHash, hashOrder_1, "MarketOrderLog, fail orderHash emited");
		assert.equal(position.price, 120 * decimalUsd, "position, fail price taken");
		assert.equal(position.amount, amountSum, "position, fail amount taken");
		assert.equal(position.positionType, 1, "position, fail positionType taken");
		assert.equal(position.leverage, leverage, "position, fail leverage taken");
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

		assert.equal(LimitOrderLog.price, price, "LimitOrderLog, fail price emited");
		assert.equal(LimitOrderLog.amount, amount, "LimitOrderLog, fail amount emited");
		assert.equal(LimitOrderLog.orderType, orderType, "LimitOrderLog, fail orderType emited");
		assert.equal(LimitOrderLog.leverage, leverage, "LimitOrderLog, fail leverage emited");
		assert.equal(limitOrder.price, price, "limitOrder, fail price ordered");
		assert.equal(limitOrder.amount, amount, "limitOrder, fail amount ordered");
		assert.equal(limitOrder.orderType, orderType, "limitOrder, fail orderType ordered");
		assert.equal(limitOrder.leverage, leverage, "limitOrder, fail leverage ordered");
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
		
		assert.equal(availableBalanceFour.toString().slice(0,-13), availableBalanceTestFour.toString().slice(0,-13), "accountFour. availableBalance fail");
		assert.equal(balanceFour.toString().slice(0,-13), balanceAccountFour.toString().slice(0,-13)	, "accountFour. Balance fail");
		assert.equal(position.amount, newPositionFourAmount, "accountFour. fail position amount");
		assert.equal(position.price, price, "accountFour. fail position price");
		assert.equal(position.leverage, positionFourLeverage, "accountFour. fail position leverage");
		assert.equal(position.positionType, 0, "accountFour. fail position positionType");

		// ACCOUNT THREE

		let positionThree = await FutureContractInstance.positions(accountThree);
		let availableBalanceThree = await DepositoryInstance.getAvailableBalance(accountThree);
		let balanceThree = await DepositoryInstance.getBalance (accountThree);
 		let pnlTestThree = calcPNL(price, currentPrice, amount, 1);
 		let positionCostTestThree = getCost(price, amount, leverage);
 		let availableBalanceTestThree = balanceAccountThree  - positionCostTestThree;

		assert.equal(balanceThree, balanceAccountThree, "accountThree. Balance fail");
		assert.equal(availableBalanceThree.toString().slice(0,-13), availableBalanceTestThree.toString().slice(0,-13), "accountThree. availableBalance fail");
		assert.equal(MarketOrderLog.amount, amount, "accountThree. MarketOrderLog, fail amount emited");
		assert.equal(MarketOrderLog.positionType, 1, "accountThree. MarketOrderLog, fail positionType emited");
		assert.equal(MarketOrderLog.orderHash, hashOrder_2, "accountThree. MarketOrderLog, fail orderHash emited");
		assert.equal(positionThree.price, price, "accountThree. positionThree, fail price taken");
		assert.equal(positionThree.amount, amount, "accountThree. positionThree, fail amount taken");
		assert.equal(positionThree.positionType, 1, "accountThree. positionThree, fail positionType taken");
		assert.equal(positionThree.leverage, leverage, "accountThree. positionThree, fail leverage taken");
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

		assert.equal(LimitOrderLog.price, price, "LimitOrderLog, fail price emited");
		assert.equal(LimitOrderLog.amount, amount, "LimitOrderLog, fail amount emited");
		assert.equal(LimitOrderLog.orderType, orderType, "LimitOrderLog, fail orderType emited");
		assert.equal(LimitOrderLog.leverage, leverage, "LimitOrderLog, fail leverage emited");
		assert.equal(limitOrder.price, price, "limitOrder, fail price ordered");
		assert.equal(limitOrder.amount, amount, "limitOrder, fail amount ordered");
		assert.equal(limitOrder.orderType, orderType, "limitOrder, fail orderType ordered");
		assert.equal(limitOrder.leverage, leverage, "limitOrder, fail leverage ordered");
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

		assert.equal(availableBalance.toString().slice(0,-13), availableBalanceTest.toString().slice(0,-13), "accountFour. availableBalance fail");
		assert.equal(balance.toString().slice(0,-13), balanceAccountFour.toString().slice(0,-13), "accountFour. Balance fail");
		assert.equal(MarketOrderLog.amount, amount, "accountFour. MarketOrderLog, fail amount emited");
		assert.equal(MarketOrderLog.positionType, 1, "accountFour. MarketOrderLog, fail positionType emited");
		assert.equal(MarketOrderLog.orderHash, hashOrder_3, "accountFour. MarketOrderLog, fail orderHash emited");
		assert.equal(positionFour.price, positionPriceFour, "accountFour. position, fail price taken");
		assert.equal(positionFour.amount, amountRes, "accountFour. position, fail amount taken");
		assert.equal(positionFour.positionType, 0, "accountFour. position, fail positionType taken");
		assert.equal(positionFour.leverage, leverage, "accountFour. position, fail leverage taken");

		//ACCOUNT TWO
		
		let positionTwo = await FutureContractInstance.positions(accountTwo);
		assert.equal(positionTwo.amount, amount, "accountTwo. position, fail amount taken");
		assert.equal(positionTwo.positionType, 0, "accountTwo. position, fail positionType taken");
		assert.equal(positionTwo.leverage, 700, "accountTwo. position, fail leverage taken");
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

		assert.equal(LimitOrderLog.price, price, "LimitOrderLog, fail price emited");
		assert.equal(LimitOrderLog.amount, amount, "LimitOrderLog, fail amount emited");
		assert.equal(LimitOrderLog.orderType, orderType, "LimitOrderLog, fail orderType emited");
		assert.equal(LimitOrderLog.leverage, leverage, "LimitOrderLog, fail leverage emited");
		assert.equal(limitOrder.price, price, "limitOrder, fail price ordered");
		assert.equal(limitOrder.amount, amount, "limitOrder, fail amount ordered");
		assert.equal(limitOrder.orderType, orderType, "limitOrder, fail orderType ordered");
		assert.equal(limitOrder.leverage, leverage, "limitOrder, fail leverage ordered");
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

		assert.equal(availableBalance.toString().slice(0,-13), availableBalanceTest.toString().slice(0,-13), "accountFour. availableBalance fail");
		assert.equal(balance.toString().slice(0,-13), balanceAccountFour.toString().slice(0,-13), "accountFour. Balance fail");
		assert.equal(MarketOrderLog.amount, amount, "accountFour. MarketOrderLog, fail amount emited");
		assert.equal(MarketOrderLog.positionType, 0, "accountFour. MarketOrderLog, fail positionType emited");
		assert.equal(MarketOrderLog.orderHash, hashOrder_4, "accountFour. MarketOrderLog, fail orderHash emited");
		assert.equal(positionFour.price, positionPriceFour, "accountFour. position, fail price taken");
		assert.equal(positionFour.amount, amountRes, "accountFour. position, fail amount taken");
		assert.equal(positionFour.positionType, 0, "accountFour. position, fail positionType taken");
		assert.equal(positionFour.leverage, leverage, "accountFour. position, fail leverage taken");

		//ACCOUNT THREE

		let positionThree = await FutureContractInstance.positions(accountThree);
		let positionPriceThree = calcPrice(positionThreeBefore.price.toNumber(), positionThreeBefore.amount.toNumber(), price, amount);

		assert.equal(positionThree.price, Math.floor(positionPriceThree), "accountThree. positionThree, fail price taken");
		assert.equal(positionThree.amount, positionThreeBefore.amount.toNumber() + amount, "accountThree. positionThree, fail amount taken");
		assert.equal(positionThree.positionType, 1, "accountThree. positionThree, fail positionType taken");
		assert.equal(positionThree.leverage, 200, "accountThree. positionThree, fail leverage taken");		
	});

	it('liquidatePosition() accountOne', async () => {
		const FutureContractInstance = await FutureContract.deployed();
		await FutureContractInstance.liquidatePosition(accountOne);
		let positionOne = await FutureContractInstance.positions(accountOne);
		assert.equal(positionOne.price, 0, "position price fail");
		assert.equal(positionOne.amount, 0, "position amount fail");
		assert.equal(positionOne.leverage, 0, "position leverage fail");

	});

	it('expirationTest() accountFour', async () => {
		const DepositoryInstance = await Depository.deployed();
		const FutureContractInstance = await FutureContract.deployed();

		let balanceFourBefore = await DepositoryInstance.getBalance(accountFour);
		let positionFourBefore = await FutureContractInstance.positions(accountFour);
		let pnlFour = calcPNL(positionFourBefore.price.toNumber(), 140*decimalUsd, positionFourBefore.amount.toNumber(), 0);
		let balanceFourTest = balanceFourBefore*1 - pnlFour[0] ;

		await FutureContractInstance.expirationTest(accountFour);

		let balanceFour = await DepositoryInstance.getBalance(accountFour);
		let positionFour = await FutureContractInstance.positions(accountFour);

		assert.equal(balanceFour.toString().slice(0,-13), balanceFourTest.toString().slice(0,-13), "fail balance");
		assert.equal(positionFour.price, 0, "position amount fail");
		assert.equal(positionFour.amount, 0, "position amount fail");
		assert.equal(positionFour.leverage, 0, "position leverage fail");
	});

	it('totalOpenedPositions()', async () => {
		const FutureContractInstance = await FutureContract.deployed();
		const totalOpenedPositions = await FutureContractInstance.totalOpenedPositions();
		assert.equal(totalOpenedPositions, 4, "totalOpenedPositions fail");
	});

	it('getTotalClosedPositions()', async () => {
		const FutureContractInstance = await FutureContract.deployed();
		const DepositoryInstance = await Depository.deployed();

		await FutureContractInstance.expirationTest(accountTwo);
		await FutureContractInstance.expirationTest(accountThree);

		const totalClosedPositions = await FutureContractInstance.getTotalClosedPositions();
		assert.equal(totalClosedPositions, 4, "totalClosedPositions fail");
	});

	it('getTotalPositivePnl()', async () => {
		const FutureContractInstance = await FutureContract.deployed();
		const totalPositivePnl = await FutureContractInstance.getTotalPositivePnl();
		assert.equal(totalPositivePnl, 1077289050000000000, "getTotalPositivePnl fail");
	});

	it('getTotalNegativePnl()', async () => {
		const FutureContractInstance = await FutureContract.deployed();
		const totalNegativePnl = await FutureContractInstance.getTotalNegativePnl();
		assert.equal(totalNegativePnl, 1017012070000000000, "getTotalNegativePnl fail");
	});

	it('allTimeProfit()', async () => {
		const DepositoryInstance = await Depository.deployed();
		allTimeProfit = await DepositoryInstance.allTimeProfit();
		assert.equal(allTimeProfit, 11537500000000000, "allTimeProfit fail");
	});

	it('marginBank()', async () => {
		const DepositoryInstance = await Depository.deployed();
		let marginBank = await DepositoryInstance.marginBank();
		assert.equal(marginBank, 0, "marginBank fail");
	});

	it('debt()', async () => {
		const DepositoryInstance = await Depository.deployed();
		let debt = await DepositoryInstance.debt();
		assert.equal(debt, 48739480000000000, "debt fail");
	});

	it('calcAccountProfit() accountFive', async () => {
		const DepositoryInstance = await Depository.deployed();
		let accountStakePercent = await DepositoryInstance.getAccountStakePercent(accountFive);
		let allTimeProfit = await DepositoryInstance.allTimeProfit(); 
		let stakedFundsAmount = await DepositoryInstance.getStakedFundsOf(accountFive);
		let prevAllTimeProfit = await DepositoryInstance.getPrevAllTimeProfit(accountFive);
		let unreleasedProfit = allTimeProfit.toString()*1 - prevAllTimeProfit.toString()*1;
		let accountProfitTest = unreleasedProfit.toString()*1 * accountStakePercent.toString()*1 / 10000;
		let accountProfit = await DepositoryInstance.calcAccountProfit({ from: accountFive });
		assert.equal(accountProfit, accountProfitTest, "accountProfit fail");
	});

	it('getDividends()', async () => {
		const DepositoryInstance = await Depository.deployed();
		await DepositoryInstance.getDividends({from:accountOne});
		let ev = await DepositoryInstance.getPastEvents( 'DividendsLog', { fromBlock: 0, toBlock: 'latest' } )
		assert.equal(ev[0].returnValues.amount, 3845448750000000, "accountProfit fail");
	});

	it('redeploy future contract', async () => {
		const FutureContractInstance = await FutureContract.deployed();
		const SettingsInstance = await Settings.deployed();
		let redeployedAddress = await FutureContractInstance.redeployedAddress();
		let contractIsTrusted = await SettingsInstance.contractIsTrusted(redeployedAddress);
		assert.isBoolean(contractIsTrusted, "Redeployed Contract Is Not Trasted");
	});


});



///////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////     UTILS       ////////////////////////////////////////////////////
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
    return  div(div(amount, price)*100*decimal,leverage);
}

function calcPrice(initPrice, initAmount, price, amount){

    let div1 = div(initAmount*decimal,initPrice);
    let div2 = div(amount*decimal, price);
    let sum1 = sum(initAmount, amount);  
    let sum2 = sum(div2, div1);
    return div(sum1*decimal, sum2);
    
}
