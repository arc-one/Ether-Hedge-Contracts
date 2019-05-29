pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

contract Settings is Ownable {
    using SafeMath for uint256;
    
    struct FutureContract {
        bool trusted;
        uint256 expirationDate;
    }

    uint256 public feeLimit;
    uint256 public feeMarket;
    uint256 public activationIn;
    uint256 public maxLeverage;
    uint256 public liquidationProfit;
    uint256 public feeDiscountIndex;
    uint256 public maxMarketLength; 
    
    address public devAddress;

    uint256 public requestedToChangeFeeLimitOrder;
    uint256 public requestedToChangeFeeLimitDate;
    uint256 public requestedToChangeFeeMarketOrder;
    uint256 public requestedToChangeFeeMarketDate;
    bool public emergencyMode;

    mapping(address => FutureContract) public trustedContracts;
    mapping(address => uint256) public requestedToAddContracts;
    mapping(address => uint256) public requestedToRemoveContracts;

    event addedContract(address account);

    constructor(
        uint256 _activationIn,
        uint256 _liquidationProfit,
        uint256 _feeDiscountIndex,
        uint256 _maxMarketLength,
        uint256 _maxLeverage
        )
        public Ownable() {
            transferOwnership(msg.sender);
            
            activationIn = _activationIn;
            liquidationProfit = _liquidationProfit;
            feeDiscountIndex = _feeDiscountIndex;
            maxMarketLength = _maxMarketLength;
            devAddress = msg.sender;
            maxLeverage = _maxLeverage;
        }

    /// Add new contract
    function requestToAddContract(address account) onlyOwner public{
        requestedToAddContracts[account] = now + activationIn;
    }

    function addContract(address account, uint256 contractDuration) public {
        require((requestedToAddContracts[account]>0 && requestedToAddContracts[account] <= now && isOwner()) || 
            trustedContracts[msg.sender].trusted == true);
        trustedContracts[account].trusted = true;
        trustedContracts[account].expirationDate = now + contractDuration;
        delete requestedToAddContracts[account];
        emit addedContract(account);
    }

    /// Remove contract
    function requestToRemoveContract(address account) onlyOwner public{
        requestedToRemoveContracts[account] = now + activationIn;
    }

    function removeContract(address account) onlyOwner public {
        require(requestedToRemoveContracts[account]>0 && requestedToRemoveContracts[account]<now);
        trustedContracts[account].trusted = false;
        delete requestedToRemoveContracts[account];
    }

    /// Change limit order fee
    function requestToChangeFeeLimit(uint256 fee) onlyOwner public{
        requestedToChangeFeeLimitDate = now + activationIn;
        requestedToChangeFeeLimitOrder = fee;
    }

    function changeFeeLimit() onlyOwner public {
        require(requestedToChangeFeeLimitDate>0 && requestedToChangeFeeLimitDate<=now);
        feeLimit = requestedToChangeFeeLimitOrder;
        requestedToChangeFeeLimitDate = 0;
    }

    /// Change market order fee
    function requestToChangeFeeMarket(uint256 fee) onlyOwner public{
        requestedToChangeFeeMarketDate = now + activationIn;
        requestedToChangeFeeMarketOrder = fee;
    }

    function changeFeeMarket() onlyOwner public {
        require(requestedToChangeFeeMarketDate>0 && requestedToChangeFeeMarketDate<=now);
        feeMarket = requestedToChangeFeeMarketOrder;
        requestedToChangeFeeMarketDate = 0;
    }

    function getDevAccount() public view returns (address){
        return owner();
    }


    /// @dev gives the owner the possibility to put the Interface into an emergencyMode, which will
    /// output always a price of 600 USD. This gives everyone time to set up a new pricefeed.
    function raiseEmergency(bool _emergencyMode) public onlyOwner {
        emergencyMode = _emergencyMode;
    }

    function getFeeMarketOrder() public view returns (uint256) {
        return feeMarket;
    }

    function isContractTrusted (address account) public view returns(bool) {
        return trustedContracts[account].trusted;
    }

    function isContractNotExpired (address account) public view returns(bool) {
        return (now < trustedContracts[account].expirationDate);
    }

    function getFeeLimitOrder() public view returns (uint256) {
        return feeLimit;
    }

    function getEmergencyMode() public view returns (bool) {
        return emergencyMode;
    }

    function getmaxLeverage() public view returns (uint256) {
        return maxLeverage;
    }




}
