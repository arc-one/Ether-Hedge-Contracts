pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./Depository.sol";
import "./MainToken.sol";

contract Settings is Ownable{
        
        using SafeMath for uint256;

        struct Proposal {
            uint256 yes;
            uint256 no;
            uint256 totalAccounts;
            uint256 endVotingDate;
            uint256 activationDate;
            uint256 propType;
            bool    activated;
            address creator;
            bytes32 ipfs;
            address priceFeedSource;
            address futureContract;

            // Since Solidity has a Stack restrictions, some of the variables we are using for different purposes
            uint256 value_1; // using for payment of Future Contracts or value of Params
            uint256 value_2; // using for expiresIn of Future Contracts or number of param in Params
        }

        struct FContract {
            bool trusted;
            uint256 expirationDate;
            uint256 activationDate;
            uint256 terms;
        }
            
        struct Voter {
            uint256 amount;
            bool vote;
        }
        
        struct Param {
            uint256 value;
            bytes32 proposalHash;
            uint256 activationDate;
        }

        mapping(bytes32 => Proposal) public proposals;
        mapping(bytes32 => uint256) public blocks;
        mapping(address => mapping(bytes32 => Voter)) public voters;
        mapping(address => uint256) public stakeLockedUntil;
        mapping(address => FContract) public trustedContracts;

        ERC20Mintable mainToken;
        Depository public depository;
        Param[] public params;
        address payable public depositoryAddress;
        address public  priceFeedSource;
        bool public emergencyMode;
        uint256 trustedContractsNum;
        uint256 version;
        bytes32 ipfsBytes; 

        event ProposalLog(
            bytes32 indexed hash, 
            uint256 startDate, 
            uint256 endDate, 
            string title, 
            string description, 
            string url, 
            uint256 propType); 
        event votedLog(address indexed voter, bool vote, bytes32 indexed hash);
        event addedContractLog(address indexed futureContract);
        event removedContractLog (address indexed futureContract);
        event activatedAddContractProposal (address indexed sender, bytes32 indexed hash);
        
        constructor(
            uint256  _votingTime,
            uint256  _activationIn,
            uint256  _feeLimit,
            uint256  _feeMarket,
            uint256  _maxLeverage,
            uint256  _liquidationProfit,
            uint256  _minVotingPercent,
            uint256  _paramProposalFee,
            uint256  _futureContractProposalFee,
            uint256  _feeDiscountIndex,
            uint256  _maxMarketLength,
            uint256  _blockVotingFee,
            uint256  _maxServicePayment,
            address  _mainTokenAddress,
            address  _priceFeedSource,
            bytes32  _ipfsBytes
        ) public {
            
            for (uint256 n = 0; n < 13; n++) {
                Param memory param;
                param.activationDate = now;
                params.push(param); 
            }
            
            params[0].value = _votingTime;
            params[1].value = _activationIn;
            params[2].value = _feeLimit;
            params[3].value = _feeMarket;
            params[4].value = _maxLeverage;
            params[5].value = _liquidationProfit;
            params[6].value = _minVotingPercent;
            params[7].value = _paramProposalFee;
            params[8].value = _futureContractProposalFee;
            params[9].value = _feeDiscountIndex;
            params[10].value = _maxMarketLength;
            params[11].value = _blockVotingFee;
            params[12].value = _maxServicePayment;

            priceFeedSource = _priceFeedSource;
            mainToken = MainToken(_mainTokenAddress);
            ipfsBytes = _ipfsBytes;
        }

        function setDepository(address payable addr ) public onlyOwner{
            require (depositoryAddress == address(0));
            depository = Depository(addr);
            depositoryAddress = addr;
        }

        function addContractProposal(
            address futureContract, 
            uint256 expiresIn, 
            string memory title, 
            string memory description, 
            bytes32 ipfs, 
            string memory url, 
            uint256 payment
        ) public payable {

            require(getContractProposalFee() == msg.value, 'Creator should pay fee.');
            require (mainToken.totalSupply().mul(getMaxServicePayment()).div(10000) > payment, 'Requested payment is too large');
            
            bytes32 hash = sha256(abi.encodePacked(msg.sender, now));

            proposals[hash].endVotingDate = now + getVotingTime();
            proposals[hash].activationDate = now + getVotingTime() + getActivationTime();
            proposals[hash].creator = msg.sender;
            proposals[hash].propType = 0;
            proposals[hash].value_2 = expiresIn;
            proposals[hash].value_1 = payment;
            proposals[hash].futureContract = futureContract;
            proposals[hash].ipfs = ipfs;

            //depositoryAddress.transfer(msg.value);

            emit ProposalLog(hash, now, proposals[hash].endVotingDate, title, description, url, 0);

        }

        function removeContractProposal(
            address futureContract, 
            string memory description, 
            bytes32 ipfs
        ) public payable {

                require(getContractProposalFee() == msg.value, 'Creator should pay fee.');
                bytes32 hash = sha256(abi.encodePacked(msg.sender, now));

                proposals[hash].endVotingDate = now + getVotingTime();
                proposals[hash].activationDate = now + getVotingTime() + getActivationTime();
                proposals[hash].creator = msg.sender;
                proposals[hash].propType = 1;
                proposals[hash].futureContract = futureContract;
                proposals[hash].ipfs = ipfs;

                //depositoryAddress.transfer(msg.value);
                emit ProposalLog(hash, now, proposals[hash].endVotingDate, '', description, '', 1);
            }


        function paramProposal(
            uint256 param,
            uint256 value,
            string memory description
            ) public payable {

                require(getParamProposalFee() == msg.value, 'Creator should pay fee.');
                bytes32 hash = sha256(abi.encodePacked(msg.sender, now));

                proposals[hash].endVotingDate = now + getVotingTime();
                proposals[hash].activationDate = now + getVotingTime() + getActivationTime();
                proposals[hash].creator = msg.sender;
                proposals[hash].propType = 2;
                proposals[hash].value_1 = value;
                proposals[hash].value_2 = param;
            
                //depositoryAddress.transfer(msg.value);
               emit ProposalLog(hash, now, proposals[hash].endVotingDate, '', description, '', 2);
            }

        function addServiceProposal(
            string memory title, 
            string memory description, 
            string memory url, 
            uint256 payment
            ) public payable {

                require(getParamProposalFee() == msg.value, 'Creator should pay fee.');
                require (mainToken.totalSupply().mul(getMaxServicePayment()).div(10000) > payment, 'Requested payment is too large');
                bytes32 hash = sha256(abi.encodePacked(msg.sender, now));

                proposals[hash].endVotingDate = now + getVotingTime();
                proposals[hash].activationDate = now + getVotingTime() + getActivationTime();
                proposals[hash].creator = msg.sender;
                proposals[hash].propType = 3;
                proposals[hash].value_1 = payment;

                //depositoryAddress.transfer(msg.value);
                emit ProposalLog(hash, now, proposals[hash].endVotingDate, title, description, url, 3);
            }

        function changePriceFeedProposal(
            string memory title, 
            string memory description, 
            address _priceFeedSource
            ) public payable {

                require(getParamProposalFee() == msg.value, 'Creator should pay fee.');
                bytes32 hash = sha256(abi.encodePacked(msg.sender, now));

                proposals[hash].endVotingDate = now + getVotingTime();
                proposals[hash].activationDate = now + getVotingTime() + getActivationTime();
                proposals[hash].creator = msg.sender;
                proposals[hash].propType = 4;
                proposals[hash].priceFeedSource = _priceFeedSource;

                //depositoryAddress.transfer(msg.value);
                emit ProposalLog(hash, now, proposals[hash].endVotingDate, title, description, '', 4);
            }

        function voteProposal(bool vote, bytes32 hash ) public {
            uint256 amount = depository.getStakedFundsOf(msg.sender);
           
            require(amount > 0, 'Staked amount should be more then 0.');
            require(proposals[hash].endVotingDate > now, 'Voting Time Expired.');
            require(voters[msg.sender][hash].amount == 0, 'The account voted already.');

            if(vote) {
                proposals[hash].yes = proposals[hash].yes.add(amount);
            } else {
                proposals[hash].no = proposals[hash].no.add(amount);
            }

            proposals[hash].totalAccounts = proposals[hash].totalAccounts.add(1);
            voters[msg.sender][hash].amount = amount;
            voters[msg.sender][hash].vote = vote;
            stakeLockedUntil[msg.sender] = proposals[hash].endVotingDate;

            emit votedLog(msg.sender, vote, hash);
        }

        function activateProposal(bytes32 hash) public {
            uint totalAmountVoted = proposals[hash].yes.add(proposals[hash].no);
            require(checkMinVotingPercent(totalAmountVoted));
            require(proposals[hash].yes > proposals[hash].no);
            require(proposals[hash].activationDate < now);
            require(!proposals[hash].activated);
            require (blocks[hash].add(proposals[hash].no)<proposals[hash].yes);
            
            if(proposals[hash].propType == 0) { 
                trustedContracts[proposals[hash].futureContract] = FContract({
                    trusted: true, 
                    expirationDate: now + proposals[hash].value_2,
                    terms: proposals[hash].value_2,
                    activationDate: now
                });
                trustedContractsNum = trustedContractsNum.add(1);
                version = version.add(1);
                setIpfsBytes(proposals[hash].ipfs);
                require(mainToken.mint(proposals[hash].creator, proposals[hash].value_1));
                emit addedContractLog (proposals[hash].futureContract);
            }

            if(proposals[hash].propType == 1) { 
                trustedContracts[proposals[hash].futureContract].trusted = false;
                trustedContractsNum = trustedContractsNum.sub(1);
                version = version.add(1);
                setIpfsBytes(proposals[hash].ipfs);
                emit removedContractLog (proposals[hash].futureContract);
            }

            if(proposals[hash].propType == 2) { 
                params[proposals[hash].value_2].value = proposals[hash].value_1;
                params[proposals[hash].value_2].activationDate = now;
                params[proposals[hash].value_2].proposalHash = hash;
            }

            if(proposals[hash].propType == 3) { 
                require(mainToken.mint(proposals[hash].creator, proposals[hash].value_1));
            }

            if(proposals[hash].propType == 4) { 
                priceFeedSource = proposals[hash].priceFeedSource;
            }

            proposals[hash].activated = true;

            emit activatedAddContractProposal(msg.sender, hash);
        }
    
        function blockVoting(bytes32 hash) payable public {
            uint256 amount = depository.getStakedFundsOf(msg.sender);
            require(depository.getStakedFundsOf(msg.sender)>0, 'Staked amount should be more then 0.');
            require(proposals[hash].yes > proposals[hash].no, 'Yes < No');
            require(proposals[hash].endVotingDate < now, 'Voting still pending');
            require(proposals[hash].activationDate > now, 'Past Activation date');
            require(!proposals[hash].activated, 'Proposal Activated Already');
            require(getBlockVotingFee() == msg.value, 'No Fee.');
            require(voters[msg.sender][hash].vote == true || voters[msg.sender][hash].amount == 0, 'No rights to block voting');
            stakeLockedUntil[msg.sender] = proposals[hash].activationDate;
            blocks[hash] = blocks[hash].add(amount);
        }

        function addContract(address addr, uint256 expiresIn) public {
            // Posible to add very first futureContract or redeploy the existing one
            require(
                contractIsTrusted(msg.sender) || 
                (isOwner() && trustedContractsNum == 0), 
                'only owner and first time'
            );
            trustedContracts[addr] = FContract({
                trusted: true,  
                expirationDate: now + expiresIn,
                activationDate: now,
                terms: expiresIn
            });

            trustedContractsNum = trustedContractsNum.add(1);
            emit addedContractLog (addr);
        }

        function getIpfsBytes() public view returns(bytes32){
            return ipfsBytes;
        }
        function setIpfsBytes(bytes32 _ipfsBytes) private {
            ipfsBytes = _ipfsBytes;
        }

        function checkMinVotingPercent(uint totalAmountVoted) public view returns(bool) {
            return (getMinVotingPercent() > depository.totalStakedFunds().mul(100).div(totalAmountVoted));
        }
    
        function getVotingTime() public view returns (uint256) { return params[0].value; }
        function getActivationTime() public view returns (uint256) { return params[1].value; }
        function getLimitOrderFee() public view returns (uint256) { return params[2].value; }
        function getMarketOrderFee() public view returns (uint256) { return params[3].value; }        
        function getMaxLeverage() public view returns (uint256) { return params[4].value; }        
        function getLiquidationProfit() public view returns (uint256) { return params[5].value; }        
        function getMinVotingPercent() public view returns (uint256) { return params[6].value; }        
        function getParamProposalFee() public view returns (uint256) { return params[7].value; }        
        function getContractProposalFee() public view returns (uint256) { return params[8].value; }        
        function getFeeDiscountIndex() public view returns (uint256) { return params[9].value; }        
        function getMaxMarketLength() public view returns (uint256) { return params[10].value; }
        function getBlockVotingFee() public view returns (uint256) { return params[11].value; }  
        function getMaxServicePayment() public view returns (uint256) { return params[12].value; }  

        function getPriceFeedSource() public view returns(address){
            return priceFeedSource;
        }
        function getAccountVote(address account, bytes32 hash) public view returns(bool){
            return voters[account][hash].vote;
        }
        function getAccountVoteAmount(address account, bytes32 hash) public view returns(uint256){
            return voters[account][hash].amount;
        }

        /// @dev gives the owner the possibility to put the Interface into an emergencyMode, which will
        /// output always a price of 600 USD. This gives everyone time to set up a new pricefeed.
        function raiseEmergency(bool _emergencyMode) public onlyOwner {
            emergencyMode = _emergencyMode;
        }

        function contractIsTrusted (address account) public view returns(bool) {
            return trustedContracts[account].trusted;
        }

        function contractIsNotExpired (address account) public view returns(bool) {
            return (now < trustedContracts[account].expirationDate);
        }

        function getContractTerms (address account) public view returns(uint256) {
            return trustedContracts[account].terms;
        }

        function getEmergencyMode() public view returns (bool) {
            return emergencyMode;
        }

        function stakeIsLocked(address account) public view returns (bool) {
            return now < stakeLockedUntil[account];
        }

}
