pragma solidity ^0.5.0;

import "./Depository.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

contract SettingsNew {
        
        using SafeMath for uint256;
    
        event contractVoteLog(address indexed voter, bool vote,address indexed addr);
        event createContractProposalLog(address indexed voter, address _contract, uint256 startDate, uint256 endDate, uint256 activationDate, uint256 expirationDate, string title, string description, string extra);   
        event quitContractVotingLog(address indexed voter,  bool vote, uint256 amount, address indexed addr);
        event createParamProposalLog(address indexed voter, uint256 param, bytes32 hash, uint256 newValue, uint256 startDate, uint256 endDate, uint256 activationDate);
        event paramVoteLog(address indexed voter, bool vote, bytes32 indexed hash, uint256 indexed param);
        event quitParamsVotingLog(address indexed voter, bool vote, uint256 amount, bytes32 hash, uint256 param);
        
        Depository public depository;
        
        struct ParamsProposal {
            uint256 yes;
            uint256 no;
            uint256 endVotingDate;
            uint256 activationDate;
            bool activated;
            uint256 newValue;
        }
        
        struct ContractProposal {
            uint256 yes;
            uint256 no;
            uint256 endVotingDate;
            uint256 activationDate;
            bool activated;
            uint256 expirationDate;
        }

        struct FContract {
            bool trusted;
            uint256 expirationDate;
        }

        struct lockedStake {
            uint256 until;
            uint256 votings;
        }
        
        struct Voter {
            uint256 amount;
            bool vote;
        }

        mapping(uint256 => mapping(bytes32 => ParamsProposal)) public paramProposals;
        mapping(address => mapping(uint256 => mapping(bytes32 => Voter))) public votersPP;
        mapping(address => ContractProposal) public contrProposals;
        mapping(address => mapping(address => Voter)) public votersCP;
        mapping(address => lockedStake) public lockedStakes;
        mapping(address => FContract) public trustedContracts;
        uint256[] public params;
        address payable public depositoryAddress;

        
        constructor(
            uint256  _votingTime,
            uint256  _activationIn,
            uint256  _feeLimit,
            uint256  _feeMarket,
            uint256  _maxLeverage,
            uint256  _liquidationProfit,
            uint256  _minVotingPercent,
            uint256  _paramProposalFee,
            uint256  _contractProposalFee,
            uint256  _feeDiscountIndex,
            uint256  _maxMarketLength,
            address  payable _depository
        ) public {
            params.push(_votingTime); 
            params.push(_activationIn); 
            params.push(_feeLimit);
            params.push(_feeMarket);
            params.push(_maxLeverage);
            params.push(_liquidationProfit);
            params.push(_minVotingPercent);
            params.push(_paramProposalFee);
            params.push(_contractProposalFee);
            params.push(_feeDiscountIndex);
            params.push(_maxMarketLength);
            depository = Depository(_depository);
            depositoryAddress = _depository;
        }


        /*------------------------ Add Contract ---------------------*/

        function createContractProposal(address addr, uint256 expiresIn, string memory title, string memory description, string memory extra) public payable {
            require(getContractProposalFee() == msg.value);
            uint256 endVotingDate = now + getVotingTime();
            uint256 activationDate = now + getVotingTime() + getActivationTime();
            contrProposals[addr].endVotingDate = endVotingDate;
            contrProposals[addr].activationDate = activationDate;
            contrProposals[addr].expirationDate = now + getVotingTime() + getActivationTime() + expiresIn;

            depositoryAddress.transfer(msg.value);
            emit createContractProposalLog(msg.sender, addr, now, endVotingDate, activationDate, contrProposals[addr].expirationDate, title, description, extra);
        }

        function voteContractProposal(bool vote, address addr ) public {
            uint256 amount = depository.getStakedFundsOf(msg.sender);
            require(amount>0);
            require(contrProposals[addr].endVotingDate > now);
            require(votersCP[msg.sender][addr].amount == 0);

            if(vote) {
                contrProposals[addr].yes = contrProposals[addr].yes.add(amount);
            } else {
                contrProposals[addr].no = contrProposals[addr].no.add(amount);
            }

            votersCP[msg.sender][addr].amount.add(amount);
            votersCP[msg.sender][addr].vote = vote;

            if(lockedStakes[msg.sender].until < contrProposals[addr].endVotingDate) {
                lockedStakes[msg.sender].until = contrProposals[addr].endVotingDate;
                lockedStakes[msg.sender].votings = lockedStakes[msg.sender].votings.add(1);
            }
            
            emit contractVoteLog(msg.sender, vote, addr);
        }

        
        function quitContractVoting(address addr) public {

            if(votersCP[msg.sender][addr].amount > 0){
                lockedStakes[msg.sender].votings.sub(1);
                
                if(votersCP[msg.sender][addr].vote){ 
                    contrProposals[addr].yes.sub(votersCP[msg.sender][addr].amount);
                } else {
                    contrProposals[addr].no.sub(votersCP[msg.sender][addr].amount);
                }
            }

            emit quitContractVotingLog(
                msg.sender, 
                votersCP[msg.sender][addr].vote, 
                votersCP[msg.sender][addr].amount, 
                addr
                );
        }
          
        function activateContractProposal(address addr) public {
            uint totalAmountVoted = contrProposals[addr].yes.add(contrProposals[addr].no);
            require(checkMinVotingPercent(totalAmountVoted));
            require(!contrProposals[addr].activated);
            require(contrProposals[addr].yes > contrProposals[addr].no);
            require(contrProposals[addr].endVotingDate < now);
            require(contrProposals[addr].activationDate < now);
            trustedContracts[addr] = FContract({trusted: true, expirationDate: contrProposals[addr].expirationDate});
            contrProposals[addr].activated = true;
        }
        

        /*------------------------ Params ---------------------*/

        function createParamProposal(uint256 param, uint256 value) public payable {
            require(getParamProposalFee() == msg.value);

            uint256 endVotingDate = now + getVotingTime();
            uint256 activationDate = now + getVotingTime() + getActivationTime();
            bytes32 hash = sha256(abi.encodePacked(msg.sender, now));
            
            paramProposals[param][hash].newValue = value;
            paramProposals[param][hash].endVotingDate = endVotingDate;
            paramProposals[param][hash].activationDate = activationDate;
            
            depositoryAddress.transfer(msg.value);
            emit createParamProposalLog(msg.sender, param, hash, value, now, endVotingDate, activationDate);
        }
    
        function voteParamProposal(bool vote, uint256 param, bytes32 hash ) public {
            uint256 amount = depository.getStakedFundsOf(msg.sender);
    
            require(amount>0);
            require(paramProposals[param][hash].endVotingDate > now);
            require(votersPP[msg.sender][param][hash].amount == 0);

            if(vote) {
                paramProposals[param][hash].yes = paramProposals[param][hash].yes.add(amount);
            } else {
                paramProposals[param][hash].no = paramProposals[param][hash].no.add(amount);
            }

            votersPP[msg.sender][param][hash].amount = amount;
            votersPP[msg.sender][param][hash].vote = vote;

            if(lockedStakes[msg.sender].until < paramProposals[param][hash].endVotingDate) {
                lockedStakes[msg.sender].until = paramProposals[param][hash].endVotingDate;
                lockedStakes[msg.sender].votings = lockedStakes[msg.sender].votings.add(1);
            }
            
            emit paramVoteLog(msg.sender, vote, hash, param);
        }
        
        
        function quitParamsVoting(uint256 param, bytes32 hash) public {
            if(votersPP[msg.sender][param][hash].amount > 0){
                lockedStakes[msg.sender].votings.sub(1);
                
                if(votersPP[msg.sender][param][hash].vote){ 
                    paramProposals[param][hash].yes.sub(votersPP[msg.sender][param][hash].amount);
                } else {
                    paramProposals[param][hash].no.sub(votersPP[msg.sender][param][hash].amount);
                }
            }
            emit quitParamsVotingLog(
                msg.sender, 
                votersPP[msg.sender][param][hash].vote, 
                votersPP[msg.sender][param][hash].amount, 
                hash, 
                param);
        }
    
    
        function activateParamProposal(uint256 param, bytes32 hash ) public {
            
            uint totalAmountVoted = paramProposals[param][hash].yes.add(paramProposals[param][hash].no);
            require(checkMinVotingPercent(totalAmountVoted));
            require(!paramProposals[param][hash].activated);
            require(paramProposals[param][hash].yes > paramProposals[param][hash].no);
            require(paramProposals[param][hash].endVotingDate < now);
            require(paramProposals[param][hash].activationDate < now);
            params[param] = paramProposals[param][hash].newValue;
            paramProposals[param][hash].activated = true;
        }
    

        function checkMinVotingPercent(uint totalAmountVoted) public view returns(bool) {
            return (getMinVotingPercent() > depository.totalStakedFunds().mul(100).div(totalAmountVoted));
        }
    
    
        function getVotingTime() public view returns (uint256) { return params[0]; }
        function getActivationTime() public view returns (uint256) { return params[1]; }
        function getLimitOrderFee() public view returns (uint256) { return params[2]; }
        function getMarketOrderFee() public view returns (uint256) { return params[3]; }        
        function getMaxLeverage() public view returns (uint256) { return params[4]; }        
        function getLiquidationProfit() public view returns (uint256) { return params[5]; }        
        function getMinVotingPercent() public view returns (uint256) { return params[6]; }        
        function getParamProposalFee() public view returns (uint256) { return params[7]; }        
        function getContractProposalFee() public view returns (uint256) { return params[8]; }        
        function getFeeDiscountIndex() public view returns (uint256) { return params[9]; }        
        function getMaxMarketLength() public view returns (uint256) { return params[10]; }
    
}





