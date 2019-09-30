pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/utils/ReentrancyGuard.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./Oracle/Medianizer.sol";
import "./Token.sol";
import "./Settings.sol";

/**
 * @title Depository
 * @dev The contract stores and manages all the funds of the project.
 */
contract Depository is ReentrancyGuard{

    using SafeMath for uint256;

    ERC20Mintable token;
    ERC20 mainToken;
    Settings settings;
    

    struct Staker {
        uint256 amount;
        uint256 prevAllTimeProfit;
    }

    mapping(address => Staker) private stakedFunds;
    mapping(address => uint256) private balances;
    mapping(address => uint256) private availableBalances;
    mapping(address => uint256) private releasedDividends;

    uint256 public totalStakedFunds;
    uint256 public totalDividends;
    uint256 public allTimeProfit;
    uint256 public marginBank;
    uint256 public debt;

    uint256 private percentMultiplyer = 100;

    event Deposited(address indexed payee, uint256 weiAmount);
    event Withdrawn(address indexed payee, uint256 weiAmount);
    event Staked(address indexed payee, uint256 weiAmount);
    event Unstaked(address indexed payee, uint256 weiAmount);
    event DividendsLog(address indexed account, uint256 amount, uint256 allTimeProfit);
    event RecievedLog(address account, uint256 amount);
    
    /**
     * @dev Constructor
     */
    constructor (
        address _settingsAddress,
        address _tokenAddress,
        address _mainTokenAddress
    ) public payable {
        token = Token(_tokenAddress);
        mainToken = Token(_mainTokenAddress);
        settings = Settings(_settingsAddress);
    }

    /**
     * @dev payable fallback
     */
    function() external payable {
        allTimeProfit = allTimeProfit.add(msg.value);
        emit RecievedLog(msg.sender, msg.value);
     }

    function deposit() public payable {
        uint256 amount = msg.value;
        balances[msg.sender] = balances[msg.sender].add(amount);
        availableBalances[msg.sender] = availableBalances[msg.sender].add(amount);
        emit Deposited(msg.sender, amount);
    }

    function withdraw(uint256 amount) public nonReentrant{
        require(availableBalances[msg.sender] >= amount);
        balances[msg.sender] = balances[msg.sender].sub(amount);
        availableBalances[msg.sender] = availableBalances[msg.sender].sub(amount);
        msg.sender.transfer(amount);
        emit Withdrawn(msg.sender, amount);
    }

    function stake(uint256 tokens) public payable {
        require(msg.sender != address(0) && tokens != 0);
        getDividends();
        ERC20(address(mainToken)).transferFrom(msg.sender, address(this), tokens);
        totalStakedFunds = totalStakedFunds.add(tokens);
        stakedFunds[msg.sender].amount = stakedFunds[msg.sender].amount.add(tokens);
        emit Staked(msg.sender, tokens);
    }

    function unstake(uint256 amount) public  {
        require(amount <= stakedFunds[msg.sender].amount && msg.sender != address(0));
        require (!settings.stakeIsLocked(msg.sender));
        getDividends();
        totalStakedFunds = totalStakedFunds.sub(amount);
        stakedFunds[msg.sender].amount = stakedFunds[msg.sender].amount.sub(amount);
        ERC20(address(mainToken)).transfer(msg.sender, amount);
        emit Unstaked(msg.sender, amount);
    }

    function getDividends() public {
        uint256 accountProfit = calcAccountProfit();
        if (accountProfit>0) {
            msg.sender.transfer(accountProfit);
            stakedFunds[msg.sender].prevAllTimeProfit = allTimeProfit;
            totalDividends = totalDividends.add(accountProfit);    
            releasedDividends[msg.sender] = releasedDividends[msg.sender].add(accountProfit); 
            emit DividendsLog(msg.sender, accountProfit, allTimeProfit);    
        } else {
            stakedFunds[msg.sender].prevAllTimeProfit = allTimeProfit;
        }
    }


    function updateBalances (address account, uint256 balance, uint256 availableBalance, uint256 feeValue, bool closePosition) public  {
        require(
            settings.contractIsTrusted(msg.sender) && 
            (settings.contractIsNotExpired(msg.sender) || closePosition)
        );

        // if a loss occurs, create new tokens
        if(balances[account] > balance) {
            uint256 lossAmount = balances[account].sub(balance);
            require(token.mint(account, lossAmount));
        }

        uint256 discountPercent = calcDiscountFeePercent(account, feeValue);
        uint256 feeValueWithDiscount = calcFeeValueWithDiscount(discountPercent, feeValue);

        allTimeProfit = allTimeProfit.add(feeValueWithDiscount);

        if(availableBalance >= feeValueWithDiscount) {
            balance = balance.sub(feeValueWithDiscount);
            availableBalance = availableBalance.sub(feeValueWithDiscount);   
        }

        balances[account] = balance;
        availableBalances[account] = availableBalance; 

    }

    function decreaseMarginBank(uint256 sum) public {
        require(settings.contractIsTrusted(msg.sender));
        if(marginBank>=sum) {
            marginBank = marginBank.sub(sum);
        } else {
            debt = debt.add(sum.sub(marginBank));
            marginBank = 0;
        }
    }

    
    function setProfit(uint256 profit) public {
        require(settings.contractIsTrusted(msg.sender));

        // the profit splitting on 2 parts: 
        // 1 - profit that all stakeholders take. Percentage is specified in liquidationProfit();
        uint256 liquidationProfitValue = profit.mul(settings.getLiquidationProfit()).div(percentMultiplyer.mul(100));
         
        allTimeProfit = allTimeProfit.add(liquidationProfitValue);

        // 2 - the rest goes to the margin bank fund. If the system has a debt we cover debt.
        uint256 marginBankProfitValue = profit.mul(percentMultiplyer.mul(100).sub(settings.getLiquidationProfit())).div(percentMultiplyer.mul(100));
        if(debt > marginBank) {
            if(debt > marginBankProfitValue) {
                debt = debt.sub(marginBankProfitValue);
            } else {
                debt=0;
                marginBank = marginBank.add(debt.sub(marginBank));
            }
        } else {
            marginBank = marginBank.add(profit.sub(marginBankProfitValue));
        }
        
    }

    /// View methods

    function calcDiscountFeePercent(address account, uint256 feeValue) public view returns (uint256){
        uint256 discountPercent;
        uint256 accountTokenBalance = token.balanceOf(account);
        uint256 tokenTotalSupply = token.totalSupply();

        if(tokenTotalSupply>0) discountPercent = accountTokenBalance.mul(percentMultiplyer.mul(100)).mul(settings.getFeeDiscountIndex()).div(tokenTotalSupply);
        if(feeValue == 0 || discountPercent >= percentMultiplyer.mul(percentMultiplyer)) {
            return percentMultiplyer.mul(100);
        }
        return discountPercent;
    }

    function getAccountStakePercent(address account) public view returns (uint256){
        if(totalStakedFunds==0) return 0;
        return stakedFunds[account].amount.mul(percentMultiplyer.mul(100)).div(totalStakedFunds);
    }

    function calcAccountProfit() public view returns (uint256){
        uint256 stakePercent = getAccountStakePercent(msg.sender);
        uint256 unreleasedProfit = allTimeProfit.sub(stakedFunds[msg.sender].prevAllTimeProfit);
        uint256 profit = unreleasedProfit.mul(stakePercent).div(percentMultiplyer.mul(100));
        return profit;
    }

    function calcFeeValueWithDiscount(uint256 discountPercent, uint256 feeValue) public view returns (uint256){
        return feeValue.mul(percentMultiplyer.mul(100).sub(discountPercent)).div(percentMultiplyer.mul(100));
    }

    function getBalance (address account) public view returns(uint256) {
        return balances[account];
    }
    
    function getAvailableBalance (address account) public view returns(uint256) {
        return availableBalances[account];
    }

    function getStakedFundsOf(address account) public view returns(uint256) {
        return stakedFunds[account].amount;
    }
    function getPrevAllTimeProfit(address account) public view returns(uint256) {
        return stakedFunds[account].prevAllTimeProfit;
    }

    function getTotalStakedFunds() public view returns(uint256) {
        return totalStakedFunds;
    }

    /// @dev returns the USDETH price, ie gets the USD price from Maker feed with 9 digits
    function getUSDETHPrice() public view returns (uint256) {

        (bytes32 price, ) = Medianizer(settings.getPriceFeedSource()).peek();
       // uint256 price = 230000000000000000000; //only for testing purposes
        
        // ensuring that there is no underflow or overflow possible,
        // even if the price is compromised
        uint priceUint = uint256(price).div(10**9);
        if (priceUint == 0) {
            return 1;
        }
        uint256 maxval = 1000000*10**9;
        if (priceUint > maxval) {
            return maxval;
        }
        return priceUint;
    }

}
