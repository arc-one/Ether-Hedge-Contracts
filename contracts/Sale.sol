pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/crowdsale/Crowdsale.sol";
import "openzeppelin-solidity/contracts/crowdsale/emission/MintedCrowdsale.sol";
import "openzeppelin-solidity/contracts/crowdsale/validation/TimedCrowdsale.sol";
import "openzeppelin-solidity/contracts/crowdsale/price/IncreasingPriceCrowdsale.sol";


contract Sale is Crowdsale, TimedCrowdsale, IncreasingPriceCrowdsale, MintedCrowdsale {
    constructor(
        uint256 _rate,
        address payable _wallet,
        ERC20 _token,
        uint256 _openingTime,
        uint256 _closingTime,
        uint256 _initialRate, 
        uint256 _finalRate
    )
        TimedCrowdsale(_openingTime, _closingTime)
        IncreasingPriceCrowdsale(_initialRate, _finalRate)
        MintedCrowdsale()
        Crowdsale(_rate, _wallet, _token)
        public
    {

    }
}
