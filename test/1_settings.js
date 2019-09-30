const truffleAssert = require('truffle-assertions');
const bs58 = require('bs58');
const Sale = artifacts.require("Sale");
const MainToken = artifacts.require("MainToken");
const FutureContract = artifacts.require("FutureContract");
const Settings = artifacts.require("Settings");
const Depository = artifacts.require("Depository");
const Meta = artifacts.require("Meta");
const Token = artifacts.require("Token");
const decimalUsd = 1000000000;
const percentMultiplyer = 100;
const currentPrice = 140 * decimalUsd;
const ETHDecimals = 1000000000000000000;
const blockVotingFee = 0.1 * ETHDecimals;
const ipfs = "QmNXnCWPS2szLaQGVA6TFtiUAJB2YnFTJJFTXPGuc4wocQ";

contract('1_Settings', (accounts) => {

	const accountOne = accounts[0];
	const accountTwo = accounts[1];
	const accountThree = accounts[2];
	const accountFour = accounts[3];
	const accountFive = accounts[4];

	var balanceAccountOne = 0;
	var balanceAccountTwo = 0;
	var balanceAccountThree = 0;
	var balanceAccountFour = 0;

	function timeout(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }


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

	it('Sale. Send Ether. Each block user will get smaller amount of tokens', async () => {
		const SaleInstance = await Sale.deployed();
		const MainTokenInstance = await MainToken.deployed();
		let one_eth = 1000000000000000000;


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
		const amount = 0.05 * ETHDecimals;

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
		assert.equal(totalStakedFunds, amount*3, "totalStakedFunds wrong");
	});



	var hash1;
	it('addContractProposal()', async () => {
		const SettingsInstance = await Settings.deployed();
		const  proposalFee = 0.5 * ETHDecimals;
        const bytes32 = fromIPFSHash(ipfs);
		const ipfsBytes = '0x'+bytes32.toString('hex');

		await SettingsInstance.addContractProposal(
			'0x79be9687fdc23646141aacd465d10cbfc97cf2b3',
			5000,
			'title',
			'description',
			ipfsBytes,
			'QmV9tSDx9UiPeWExXEeH6aoDvmihvx6jD5eLb4jbTaKGps',
			1000000,
			{ from: accountOne, value: proposalFee.toString() });
		
		let ev = await SettingsInstance.getPastEvents( 'ProposalLog', { fromBlock: 0, toBlock: 'latest' } )

		hash1 = ev[0].returnValues.hash;
		assert.equal(ev[0].returnValues.hash, hash1, "addContractProposal Error");

	});



	var hash2;
	it('removeContractProposal()', async () => {
		const SettingsInstance = await Settings.deployed();
		const  proposalFee = 0.5 * ETHDecimals;

        const bytes32 = fromIPFSHash(ipfs);
		const ipfsBytes = '0x'+bytes32.toString('hex');
		await SettingsInstance.removeContractProposal(
			'0x79be9687fdc23646141aacd465d10cbfc97cf2b3',
			'description',
			ipfsBytes,
			{ from: accountTwo, value: proposalFee.toString() });
		let ev1 = await SettingsInstance.getPastEvents( 'ProposalLog', { fromBlock: 0, toBlock: 'latest' } )
		hash2 = ev1[1].returnValues.hash;
		assert.equal(ev1[1].returnValues.hash, hash2, "addContractProposal Error");
	});

	var hash3;
	it('paramProposal()', async () => {
		const SettingsInstance = await Settings.deployed();
		const  paramProposalFee = 0.3 * ETHDecimals;

		await SettingsInstance.paramProposal(
			1,
			700,
			'Hello',
			{ from: accountThree, value: paramProposalFee.toString() });
		let ev2 = await SettingsInstance.getPastEvents( 'ProposalLog', { fromBlock: 0, toBlock: 'latest' } )

		hash3 = ev2[2].returnValues.hash;
		assert.equal(ev2[2].returnValues.hash, hash3);

	});


	it('voteProposal() 1', async () => {
		const SettingsInstance = await Settings.deployed();

		await SettingsInstance.voteProposal(true, hash1,{ from: accountOne });
		await SettingsInstance.voteProposal(true, hash1,{ from: accountTwo });
		await SettingsInstance.voteProposal(false, hash1,{ from: accountThree });
		
		const proposal = await SettingsInstance.proposals(hash1);

		assert.equal(proposal.yes, 100000000000000000, 'voteProposal yes wrong');
		assert.equal(proposal.no, 50000000000000000, 'voteProposal no wrong');

	});

	it('voteProposal() 2', async () => {
		const SettingsInstance = await Settings.deployed();

		const vote = await SettingsInstance.getAccountVoteAmount(accountOne,hash2);

		await SettingsInstance.voteProposal(true, hash2,{ from: accountOne });
		await SettingsInstance.voteProposal(true, hash2,{ from: accountTwo });
		
		const proposal = await SettingsInstance.proposals(hash2);

		assert.equal(proposal.yes, 100000000000000000, 'voteProposal yes wrong');

	});

	it('blockVoting()', async () => {
		const SettingsInstance = await Settings.deployed();
		
	    await timeout(6005);
		await SettingsInstance.blockVoting(hash2, { from: accountOne, value: blockVotingFee.toString() });
		await SettingsInstance.blockVoting(hash2, { from: accountTwo, value: blockVotingFee.toString() });
		await SettingsInstance.blockVoting(hash2, { from: accountThree, value: blockVotingFee.toString() });

		const blocked = await SettingsInstance.blocks(hash2);
		assert.equal(blocked, 150000000000000000, "Block Voting error");

	});

	it('activateProposal()', async () => {
		const SettingsInstance = await Settings.deployed();

	    await timeout(10000);
		await SettingsInstance.activateProposal(hash1, { from: accountOne });
		const contract = await SettingsInstance.trustedContracts('0x79be9687fdc23646141aacd465d10cbfc97cf2b3');
		assert.isBoolean(contract.trusted, "Contract trust error");

		const returnedBytes = await SettingsInstance.getIpfsBytes.call();
		const originalCid = toIPFSHash(returnedBytes);
		assert(originalCid == ipfs, 'IPFS is wrong'); // it fails

	});

	it('unstake()', async () => {
		const DepositoryInstance = await Depository.deployed();
		const amount = 10000000000000000;
		await DepositoryInstance.unstake(amount.toString(), { from: accountOne });
		const staked = await DepositoryInstance.getStakedFundsOf(accountOne);
		assert.equal(staked, 40000000000000000,  "Contract trust error");

	});



});