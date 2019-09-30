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



contract('2_Depository', (accounts) => {

	const accountOne = accounts[0];
	const accountTwo = accounts[1];
	const accountThree = accounts[2];
	const accountFour = accounts[3];
	const accountFive = accounts[4];

	var balanceAccountOne = 0;
	var balanceAccountTwo = 0;
	var balanceAccountThree = 0;
	var balanceAccountFour = 0;


/*	it('deposit() should deposit 5 Eth for the first 4 accounts', async () => {
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

*/


});