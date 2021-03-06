pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./Oracle/PriceFeed.sol";
import "./Settings.sol";
import "./Depository.sol";
import "./Redeployer.sol";

contract FutureContract {
    
    using SafeMath for uint256;
    
    Settings settings;
    Depository depository;
    Redeployer redeployer;
    
    string  public  ticker;
    uint256 public  number;
    uint256 public  maxLeverage;
    uint256 public  maxOrderValue;
    uint256 public  minOrderValue;
    uint256 public  expirationPrice;
    uint256 public  bancrupcyDiff;    
    uint256 public  lastPrice;  
    address public  redeployedAddress;

    uint256 public totalPositivePnl;
    uint256 public totalNegativePnl;
    uint256 public totalOpenedPositions;
    uint256 public totalClosedPositions;
    uint256 public totalLiquidated;
    uint256 public totalLongsCost;
    uint256 public totalLongsAmount;
    uint256 public totalShortsCost;
    uint256 public totalShortsAmount;
   
    uint256 private decimal;  
    uint256 private minLeverage = 100;
    uint256 private hundr = 100;
    uint256 private percentMultiplyer = 100;


    constructor (
        address _settingsAddress, 
        address payable _depositoryAddress, 
        uint256 _decimal,
        uint256 _maxOrderValue,
        uint256 _minOrderValue,
        uint256 _bancrupcyDiff,
        string memory _ticker,
        uint256 _number,
        address _redeployerAddress
    ) public {
        settings = Settings(_settingsAddress);
        depository = Depository(_depositoryAddress);
        decimal = _decimal;
        maxOrderValue = _maxOrderValue.mul(10**decimal);
        minOrderValue = _minOrderValue;
        bancrupcyDiff = _bancrupcyDiff;
        number =_number;
        ticker = _ticker;
        redeployer = Redeployer(_redeployerAddress);
        maxLeverage = settings.getMaxLeverage();
    }

    struct Limit {
        uint256 amount;
        uint256 price;
        uint256 orderType;
        uint256 expires;
        uint256 leverage;
        address account;
    }
    
    struct Market {
        bytes32 orderHash;
        uint256 amount;
        uint256 leverage;
    } 
    
    struct Position {
        uint256 amount;
        uint256 price;
        uint256 leverage;
        uint256 positionType;
        bool exists;
    } 
    
    mapping (bytes32 => Limit) public orders;
    mapping (address => Position) public positions;
    mapping (bytes32 => uint256) public orderFills;
    
    event LimitOrderLog(address indexed addr, uint256 price, uint256 amount, uint256 orderType, bytes32 hash, uint256 leverage, uint256 expires);
    event MarketOrderLog(bytes32 orderHash, uint256 amount, uint256 price, uint256 positionType, address orderUser, address tradeUser, uint256 timestamp);
    event LiquidatedPosLog(uint256 amount, uint256 price, uint256 positionType, address indexed account, uint256 timestamp);
    event ExpiratedPosLog(uint256 amount, uint256 price, uint256 positionType, address indexed account, uint256 timestamp);

    event testLog(uint256 num);

    function placeLimitOrder(uint256 price, uint256 amount, uint256 orderType, uint256 leverage, uint256 expiresIn) public returns (bytes32){
        isValid(price, amount, orderType, leverage);

        bytes32 hash = sha256(abi.encodePacked(msg.sender, price, amount, now)); 
        orders[hash].account = msg.sender;
        orders[hash].price = price;
        orders[hash].amount = amount;
        orders[hash].leverage = leverage;
        orders[hash].orderType = orderType;
        orders[hash].expires = block.number.add(expiresIn)  ;

        emit LimitOrderLog(msg.sender, price, amount, orderType, hash, leverage, orders[hash].expires);
        return hash;
    }    
    
    function placeMarketOrder(bytes32[] memory orderList, uint256 amount, uint256 leverage) public {
        require(orderList.length <= settings.getMaxMarketLength(), "order list too long");
        for (uint256 i=0; i<orderList.length; i++) {
            uint256 submitAmount = trade(orderList[i], amount, leverage);
            if (submitAmount>0) {
                if (submitAmount == amount) break;
                amount = amount.sub(submitAmount);
            }
        }
    }  

    function expiration(address account) public {
        require(expirationPrice>0);
        // if emergencyMode == true users don't loose and don't earn anythig, pos just closing with initial price        
        if(settings.getEmergencyMode()) expirationPrice = positions[account].price;
        closePosition(account, expirationPrice);
        emit ExpiratedPosLog(positions[account].amount, expirationPrice, positions[account].positionType, account, now);
    }


    function liquidatePosition(address account) public {
        require (!settings.getEmergencyMode(), 'Emergency mode enabled');
        require (checkLiquidation(account, depository.getUSDETHPrice()), "Current price is higher than liquidation price"); 

        (uint256 bancrupcyPrice, uint256 liquidationPrice) = getPositionLiquidationPrice(account);
               
        Position memory pos = positions[account];

        (uint256 liquidationPNL, ) = calcPNL(pos.price, liquidationPrice, pos.amount, pos.positionType);
        (uint256 bancrupcyPNL, ) = calcPNL(pos.price, bancrupcyPrice, pos.amount, pos.positionType);       

        uint256 profit = bancrupcyPNL.sub(liquidationPNL); // count profit for the platform
        closePosition(account, liquidationPrice);

       depository.setProfit(profit);
       totalLiquidated = totalLiquidated.add(liquidationPNL);
       emit LiquidatedPosLog(pos.amount, liquidationPrice, pos.positionType, account, now);
    }

    function closePosition(address account, uint256 price) private {
        require (positions[account].exists);
        (uint256 bal, uint256 positivePnl, uint256 negativePnl) = calcBalancePNL(account, price, positions[account].amount);    
        
        depository.updateBalances (account, bal, bal, 0, true);

        delete positions[account];
        totalPositivePnl = totalPositivePnl.add(positivePnl);
        totalNegativePnl = totalNegativePnl.add(negativePnl);
        totalClosedPositions = totalClosedPositions.add(1);

        if(totalPositivePnl > totalNegativePnl){ 
            depository.decreaseMarginBank(totalPositivePnl.sub(totalNegativePnl));
        }

        // After closing all opened positions we can get additional profit - difference between total negative pnl and total positve pnl taken by traders.
        if(totalClosedPositions == totalOpenedPositions && totalNegativePnl >= totalPositivePnl  ) {
            depository.setProfit(totalNegativePnl.sub(totalPositivePnl));
        }
    }

    function setPosition(address account, uint256[8] memory result, uint256 fee, uint256 submitPrice) private {

        if(settings.contractIsNotExpired(address(this))){
            require (!settings.getEmergencyMode());
            bool exists = positions[account].exists;
            Position memory pos;
            pos.amount = result[1];
            pos.price = result[2];
            pos.positionType = result[3];
            pos.leverage = result[4];
            pos.exists = true;
            uint256 newBal = result[5];
            uint256 availableBalance = newBal.sub(getCost(pos.price, pos.amount, pos.leverage));
            uint256 submitCost = getCost(submitPrice, result[0], pos.leverage);
            uint256 feeValue = submitCost.mul(fee).div(percentMultiplyer.mul(100));

            positions[account] = pos;
            depository.updateBalances (account, newBal, availableBalance, feeValue, false);

            if(pos.positionType == 1) {
                totalLongsCost = totalLongsCost.add(submitCost);
                totalLongsAmount = totalLongsAmount.add(pos.amount);
            } else {
                totalShortsCost = totalShortsCost.add(submitCost);
                totalShortsAmount = totalShortsAmount.add(pos.amount);
            }

            totalPositivePnl = totalPositivePnl.add(result[6]);
            totalNegativePnl = totalNegativePnl.add(result[7]);

            if(totalPositivePnl > totalNegativePnl){
                depository.decreaseMarginBank(totalPositivePnl.sub(totalNegativePnl));
            }
            
            if(!exists) totalOpenedPositions = totalOpenedPositions.add(1);

        } else {
            expirationPrice = depository.getUSDETHPrice();
            redeploy();
        }
    }

    function trade(bytes32 _hash, uint256 _submitAmount, uint256 _leverage) private returns (uint256){
        Market memory m;
        m.amount = _submitAmount;
        m.leverage = _leverage;
        m.orderHash = _hash;        

        Limit memory limitOrder = orders[m.orderHash];

        if (limitOrder.amount > 0 && orderFills[m.orderHash] < limitOrder.amount && limitOrder.expires >= block.number) {
            if (orderFills[m.orderHash].add(m.amount) > limitOrder.amount) {
                m.amount = limitOrder.amount.sub(orderFills[m.orderHash]);
            } 

            isValid(limitOrder.price, m.amount, limitOrder.orderType, m.leverage);

            if (msg.sender!=limitOrder.account) {
                address longAddress = msg.sender;
                address shortAddress = limitOrder.account;
                uint256 shortLeverage  = limitOrder.leverage;
                uint256 longLeverage = m.leverage;
                uint256 shortFee = settings.getLimitOrderFee();
                uint256 longFee = settings.getMarketOrderFee();
           
                if (limitOrder.orderType == 1) {
                    shortAddress = msg.sender;                
                    longAddress = limitOrder.account;
                    shortLeverage  = m.leverage;
                    longLeverage = limitOrder.leverage;
                    shortFee = settings.getMarketOrderFee();
                    longFee = settings.getLimitOrderFee();
                }
                
                uint256 balBeforeShort = depository.getBalance(shortAddress);
                uint256 balBeforeLong = depository.getBalance(longAddress);

                uint256[8] memory shortResult = calcPosition(shortAddress, limitOrder.price, m.amount, 0, shortLeverage);
                uint256[8] memory longResult = calcPosition(longAddress, limitOrder.price, m.amount, 1, longLeverage);
    
                //recalculate if tradeAmount is less than m.amount
                if(longResult[0] < shortResult[0]) {
                    shortResult = calcPosition(shortAddress, limitOrder.price, longResult[0], 0, shortLeverage);
                } 
    
                if(longResult[0] > shortResult[0]) {
                    longResult = calcPosition(longAddress, limitOrder.price, shortResult[0], 1, longLeverage);
                }

                //prevent frontrunning;
                if(balBeforeShort == depository.getBalance(shortAddress) && balBeforeLong == depository.getBalance(longAddress)){
                    if(shortResult[1]>0) {
                        setPosition(shortAddress, shortResult, shortFee, limitOrder.price);
                        setPosition(longAddress, longResult, longFee, limitOrder.price);
                        orderFills[m.orderHash] = orderFills[m.orderHash].add(shortResult[0]);
                        lastPrice = limitOrder.price; 

                        emit MarketOrderLog(m.orderHash, shortResult[0], limitOrder.price, switchValue(limitOrder.orderType), limitOrder.account, msg.sender, now);

                    }
                    return shortResult[0];
                } else {
                    return 0;
                }
            }
        }
        return 0;
    }  

    // View and Pure methods
    
    function isValid(uint256 price, uint256 amount, uint256 orderType, uint256 leverage) private view {
        if (leverage<minLeverage) leverage = minLeverage;
        require(price>0 && 
            amount>0 && 
            (orderType==0 || orderType==1) &&
            maxLeverage >= leverage &&
            percentMultiplyer <= leverage &&
            expirationPrice==0 &&
            maxOrderValue >= amount.mul(10**decimal).div(price) && 
            minOrderValue <= amount.mul(10**decimal).div(price) 
            , "Not Valid Params");
    }

    function calcPosition(address _account, uint256 price, uint256 amount, uint256 positionType, uint256 leverage) private view returns(uint256[8] memory) {
        
        Position memory newPos;
        newPos.price = price;
        newPos.amount = amount;
        newPos.leverage = leverage;
        newPos.positionType = positionType;
        
        address account = _account;
        uint256 tradeAmount = amount;        
        uint256 posAmount = amount;
        uint256 posPrice = price;
        uint256 posLeverage = leverage;
        uint256 bal = depository.getBalance(account);
        uint256 availableBal =  depository.getAvailableBalance(account);
        uint256 positivePnl;
        uint256 negativePnl;

        Position memory pos = positions[account];

        if (pos.amount > 0 && pos.positionType == newPos.positionType) {
            if(availableBal < getCost(newPos.price, newPos.amount, newPos.leverage)){ 
                tradeAmount = getAvailableAmount(availableBal, newPos.price, newPos.leverage);
            }
            posPrice = calcPrice(pos.price, pos.amount, newPos.price, tradeAmount);
            posAmount = pos.amount.add(tradeAmount);
            
        }
        if (pos.amount > 0 && pos.positionType != newPos.positionType && newPos.amount > pos.amount) {
            (bal, positivePnl, negativePnl) = calcBalancePNL(account, newPos.price, pos.amount);
            posAmount = newPos.amount.sub(pos.amount);
            uint256 posCost = getCost(newPos.price, posAmount, newPos.leverage);
            if(bal<posCost) {
                posAmount = getAvailableAmount(bal, newPos.price, newPos.leverage);
                tradeAmount = newPos.amount.sub(posAmount);
            }
        }
        if (pos.amount > 0 && pos.positionType != newPos.positionType && newPos.amount <= pos.amount) {
            (bal, positivePnl, negativePnl) = calcBalancePNL(account, newPos.price, newPos.amount);
            positionType = pos.positionType;
            posPrice = pos.price;
            posAmount = pos.amount.sub(newPos.amount);
        }
        
        if(pos.amount == 0 && availableBal < getCost(newPos.price, newPos.amount, newPos.leverage)) {
            tradeAmount = getAvailableAmount(availableBal, newPos.price, newPos.leverage);
            posAmount = tradeAmount;
        }

        return [
            tradeAmount,    
            posAmount,
            posPrice,
            positionType, 
            posLeverage,
            bal,
            positivePnl,
            negativePnl
        ];
    }

    function getCost(uint256 price, uint256 amount, uint256 leverage) public view returns (uint256) {
        return amount.mul(percentMultiplyer).mul(10**decimal).div(price).div(leverage);
    }

    function getAvailableAmount(uint256 availableBal, uint256 price, uint256 leverage) private view returns(uint256){
        return availableBal.mul(price).mul(leverage).div(100).div(10**decimal);
    }   

    function getCurrentPositionPNL(address account) public view returns (uint256 pnl, bool prefix) {
        Position memory pos = positions[account];
        return calcPNL(pos.price, lastPrice, pos.amount, pos.positionType);
    }

    function calcPNL(uint256 initialPrice, uint256 currentPrice, uint256 amount, uint256 positionType) private view returns (uint256 pnl, bool prefix) { 
        
        //prefix mean: false - negative, true - positive

        if(positionType == 1) {
            if(initialPrice<=currentPrice) {
                return (SafeMath.mul(SafeMath.sub(SafeMath.div(10**decimal,initialPrice), SafeMath.div(10**decimal,currentPrice)),amount), true);
            } else {
                return (SafeMath.mul(SafeMath.sub(SafeMath.div(10**decimal,currentPrice), SafeMath.div(10**decimal,initialPrice)),amount), false);
            }
        }

        if(positionType == 0) {
            if(initialPrice>=currentPrice) {
                return (SafeMath.mul(SafeMath.sub(SafeMath.div(10**decimal,currentPrice), SafeMath.div(10**decimal,initialPrice)),amount), true);
            } else {
                return (SafeMath.mul(SafeMath.sub(SafeMath.div(10**decimal,initialPrice), SafeMath.div(10**decimal,currentPrice)),amount), false);
            }
        }
        
        return (0, true);
    }

    function calcPrice(uint256 initPrice, uint256 initAmount, uint256 price, uint256 amount) private view returns (uint256 _price){
        return initAmount.add(amount).mul(10**decimal).div(amount.mul(10**decimal).div(price).add(initAmount.mul(10**decimal).div(initPrice)));
    }
   
    function calcBalancePNL(address account, uint256 price, uint256 amount) private view returns (uint256, uint256, uint256){
        uint256 bal = depository.getBalance(account);
        Position memory pos = positions[account];
        
        if (pos.amount==0) return (bal, 0, 0);
        (uint256 pnl, bool prefix) = calcPNL(pos.price, price, amount, pos.positionType);
        
        if (prefix) {
            return (bal.add(pnl), pnl, 0);
        } else {
            if(pnl>=bal) return (0, 0, pnl);
            return (bal.sub(pnl), 0, pnl) ;
        }
    }



    function getPositionLiquidationPrice(address account) public view returns (uint256, uint256) {
        Position memory pos = positions[account];
        if(pos.positionType==0){
            uint256 bancrupcyPrice = pos.price.mul(pos.leverage).div((pos.leverage.sub(percentMultiplyer)));
            uint256 liquidationPrice = hundr.sub(bancrupcyDiff).mul(bancrupcyPrice.sub(pos.price)).div(hundr).add(pos.price);
            return (bancrupcyPrice, liquidationPrice);
        } else {
            uint256 bancrupcyPrice = pos.price.sub(pos.price.mul(50).mul(percentMultiplyer).div(pos.leverage).div(hundr));
            uint256 liquidationPrice = pos.price.sub((hundr.sub(bancrupcyDiff)).mul(pos.price.sub(bancrupcyPrice)).div(hundr));
            return (bancrupcyPrice, liquidationPrice);
        }
    }

    function checkLiquidation(address account, uint256 currPrice) public view returns (bool){
        Position memory pos = positions[account];
        (, uint256 liquidationPrice) = getPositionLiquidationPrice(account);
        if(pos.positionType==0){
            if(currPrice > liquidationPrice) return true;
        } else {
            if(currPrice < liquidationPrice) return true;
        }
        return false;
    } 

    function switchValue(uint256 value) private pure returns (uint256 _value){
        if (value == 0) return 1;
        if (value == 1) return 0;
        return value;
    }

    function redeploy() private {
        redeployedAddress = redeployer.deploy(address(settings), address(depository), decimal, maxOrderValue, minOrderValue, bancrupcyDiff, ticker, number+1);
        settings.addContract(redeployedAddress, settings.getContractTerms(address(this)));
    }



    function getTotalClosedPositions () public view returns(uint256) {
        return totalClosedPositions;
    }

    function getTotalNegativePnl () public view returns(uint256) {
        return totalNegativePnl;
    }


    function getTotalPositivePnl () public view returns(uint256) {
        return totalPositivePnl;
    }




    // Testing
    function expirationTest(address account) public {
        expirationPrice = 140*10**9;
        redeploy();
        expiration(account);
    }
}

