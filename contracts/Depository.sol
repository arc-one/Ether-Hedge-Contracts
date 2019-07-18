pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/utils/ReentrancyGuard.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./Oracle/PriceFeed.sol";
import "./Oracle/Medianizer.sol";
import "./Token.sol";
import "./Settings.sol";

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
    
    uint256 public totalBalance;
    uint256 public totalStakedFunds;
    uint256 public totalDividends;
    uint256 public allTimeTotalProfit;
    uint256 public marginBank;
    uint256 private percentMultiplyer;
    address public devAccount;
    address public priceFeedSource;

    event Deposited(address indexed payee, uint256 weiAmount);
    event Withdrawn(address indexed payee, uint256 weiAmount);
    event Staked(address indexed payee, uint256 weiAmount);
    event Unstaked(address indexed payee, uint256 weiAmount);

    constructor (
        address _settingsAddress,
        address _tokenAddress,
        address _mainTokenAddress,
        uint256 _percentMultiplyer,
        address _priceFeedSource
    ) public {
        token = Token(_tokenAddress);
        mainToken = Token(_mainTokenAddress);
        settings = Settings(_settingsAddress);
        percentMultiplyer = _percentMultiplyer;
        devAccount = settings.getDevAccount();
        priceFeedSource = _priceFeedSource;
    }



    function deposit() public payable {
        uint256 amount = msg.value;
        balances[msg.sender] = balances[msg.sender].add(amount);
        availableBalances[msg.sender] = availableBalances[msg.sender].add(amount);
        totalBalance = totalBalance.add(amount);
        emit Deposited(msg.sender, amount);
    }

    function withdraw(uint256 amount) public nonReentrant{
        require(availableBalances[msg.sender] >= amount);
        balances[msg.sender] = balances[msg.sender].sub(amount);
        totalBalance = totalBalance.sub(amount);
        msg.sender.transfer(amount);

        emit Withdrawn(msg.sender, amount);
    }

    function withdrawAll() public {
        withdraw(balances[msg.sender]);
    }

    function stake(uint256 tokens) public payable {
        require(msg.sender != address(0) && tokens != 0);
        getDividends();
        totalStakedFunds = totalStakedFunds.add(tokens);
        stakedFunds[msg.sender].amount = stakedFunds[msg.sender].amount.add(tokens);
        ERC20(address(mainToken)).transferFrom(msg.sender, address(this), tokens);
        emit Staked(msg.sender, tokens);
    }


    function unstake(uint256 amount) public nonReentrant {
        require(amount <= stakedFunds[msg.sender].amount && msg.sender != address(0));
        getDividends();
        totalStakedFunds = totalStakedFunds.sub(amount);
        stakedFunds[msg.sender].amount = stakedFunds[msg.sender].amount.sub(amount);
        ERC20(address(mainToken)).transfer(msg.sender, amount);
        emit Unstaked(msg.sender, amount);
    }

    function getDividends() public  {
        uint256 accountProfit =  calcAccountProfit();
        if (accountProfit>0) {
            stakedFunds[msg.sender].prevAllTimeProfit = allTimeTotalProfit;
            totalDividends = totalDividends.add(accountProfit);           
            msg.sender.transfer(accountProfit);
        }
    }

    function updateBalances (address account, uint256 balance, uint256 availableBalance, uint256 feeValue) public  {
        require(
            settings.isContractTrusted(msg.sender) && 
            settings.isContractNotExpired(msg.sender) && 
          //  totalBalance >= balance &&
            token.isMinter(address(this))
        );

        // if a loss occurs, create new tokens
        if(balances[account] > balance) {
            uint256 lossAmount = balances[account].sub(balance);
            require(token.mint(account, lossAmount));
        }

        uint256 discountPercent = calcDiscountFeePercent(account, feeValue);
        uint256 feeValueWithDiscount = calcFeeValueWithDiscount(discountPercent, feeValue);
        (balances[account], availableBalances[account], totalBalance, marginBank) = calcBalances (account, balance, availableBalance, feeValueWithDiscount);

        allTimeTotalProfit = allTimeTotalProfit.add(feeValueWithDiscount);

    }


    function calcBalances (address account, uint256 balance, uint256 availableBalance, uint256 feeValueWithDiscount) private view returns(uint256 _balance, uint256 _availableBalance, uint256 _newTotalBalance, uint256 _newMarginBank)  {
        
        uint256 diff;
        uint256 newMarginBank;
        uint256 newTotalBalance = totalBalance.add(balance).sub(balances[account]).sub(feeValueWithDiscount);
        uint256 availableTotalBalance = address(this).balance.sub(allTimeTotalProfit).sub(marginBank);

        if(newTotalBalance > availableTotalBalance) {
            diff = newTotalBalance.sub(availableTotalBalance);
            newTotalBalance = availableTotalBalance;
        }

        if(marginBank >= diff) {
            newMarginBank = marginBank.sub(diff);
        } else {
            newMarginBank = 0;
        }

        balance = balance.sub(diff).sub(feeValueWithDiscount);
        availableBalance = availableBalance.sub(diff).sub(feeValueWithDiscount);

        return (balance, availableBalance, newTotalBalance, newMarginBank);

    }
    
    function setLiquidationProfit(uint256 profit) public {
        require(settings.isContractTrusted(msg.sender));

        // the profit splitting on 2 parts: 
        // 1 - profit that all stakeholders take. Percentage is specified in liquidationProfit();
        uint256 liquidationProfitValue = profit.mul(settings.liquidationProfit()).div(100);
         
        allTimeTotalProfit = allTimeTotalProfit.add(liquidationProfitValue);
        totalBalance = totalBalance.sub(liquidationProfitValue);

        // 2 - the rest goes to the margin bank fund
        marginBank = marginBank.add(profit.sub(liquidationProfitValue));
    }

    /// View methods

    function calcDiscountFeePercent(address account, uint256 feeValue) public view returns (uint256){
        uint256 discountPercent;
        uint256 accountTokenBalance = token.balanceOf(account);
        uint256 tokenTotalSupply = token.totalSupply();

        if(tokenTotalSupply>0) discountPercent = accountTokenBalance.mul(percentMultiplyer.mul(100)).mul(settings.feeDiscountIndex()).div(tokenTotalSupply);
        if(feeValue==0 || discountPercent >= percentMultiplyer.mul(percentMultiplyer)) {
            return percentMultiplyer.mul(100);
        }
        return discountPercent;
    }

    function getAccountStakePercent(address account) public view returns (uint256){
        if(totalStakedFunds==0) return 0;
        return stakedFunds[account].amount.mul(percentMultiplyer.mul(100)).div(totalStakedFunds);
    }

    function calcAccountProfit() public view returns (uint256){
        //if(stakedFunds[msg.sender].amount == 0) return 0;
        uint256 stakePercent = getAccountStakePercent(msg.sender);
        uint256 unreleasedProfit = allTimeTotalProfit.sub(stakedFunds[msg.sender].prevAllTimeProfit);
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
    function getUSDETHPrice() public pure returns (uint256) {

        //(bytes32 price, ) = Medianizer(priceFeedSource).peek();
        uint256 price = 140000000000000000000; //only for testing purposes
        
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

    //////// testing 
    function getWalletBalance (address account) public view returns(uint256) {
        return address(account).balance;
    }



}
