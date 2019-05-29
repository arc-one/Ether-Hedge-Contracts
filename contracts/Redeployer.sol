pragma solidity ^0.5.0;

import "./FutureContract.sol";

contract Redeployer {
    constructor () public {}
    function deploy(        
        address _settingsAddress, 
        address _depositoryAddress, 
        uint256 _decimal,
        uint256 _maxOrderValue,
        uint256 _minOrderValue,
        uint256 _percentMultiplyer,
        uint256 _bancrupcyDiff,
        string memory _ticker,
        uint256 _number
        ) public returns (address){
        FutureContract futureContract = new FutureContract(_settingsAddress, _depositoryAddress, _decimal, _maxOrderValue, _minOrderValue, _percentMultiplyer, _bancrupcyDiff, _ticker, _number, address(this));

        return address(futureContract);
    }
}
