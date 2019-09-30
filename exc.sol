pragma solidity ^0.5.0;

/**
 * @title Helps contracts guard against reentrancy attacks.
 * @author Remco Bloemen <remco@2π.com>, Eenae <alexey@mixbytes.io>
 * @dev If you mark a function `nonReentrant`, you should also
 * mark it `external`.
 */
contract ReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor () internal {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter);
    }
}

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

/**
 * @dev Collection of functions related to the address type,
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * > It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://eips.ethereum.org/EIPS/eip-20
 * Originally based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 *
 * This implementation emits additional Approval events, allowing applications to reconstruct the allowance status for
 * all accounts just by listening to said events. Note that this isn't required by the specification, and other
 * compliant implementations may not do it.
 */
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

    /**
     * @dev Total number of tokens in existence
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner The address to query the balance of.
     * @return A uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

    /**
     * @dev Transfer token to a specified address
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another.
     * Note that while this function emits an Approval event, this is not required as per the specification,
     * and other compliant implementations may not emit the event.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when _allowed[msg.sender][spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when _allowed[msg.sender][spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
     * @dev Transfer token for a specified addresses
     * @param from The address to transfer from.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    /**
     * @dev Internal function that mints an amount of the token and assigns it to
     * an account. This encapsulates the modification of balances such that the
     * proper events are emitted.
     * @param account The account that will receive the created tokens.
     * @param value The amount that will be created.
     */
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account.
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Approve an address to spend another addresses' tokens.
     * @param owner The address that owns the tokens.
     * @param spender The address that will spend the tokens.
     * @param value The number of tokens that can be spent.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account, deducting from the sender's allowance for said account. Uses the
     * internal burn function.
     * Emits an Approval event (reflecting the reduced allowance).
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burnFrom(address account, uint256 value) internal {
        _burn(account, value);
        _approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
    }
}




/**
 * @title ERC20Detailed token
 * @dev The decimals are only for visualization purposes.
 * All the operations are done using the smallest and indivisible token unit,
 * just as on Ethereum all the operations are done in wei.
 */
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @return the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @return the symbol of the token.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @return the number of decimals of the token.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}



/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev give an account access to this role
     */
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

    /**
     * @dev remove an account's access to this role
     */
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

    /**
     * @dev check if an account has this role
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}



contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender));
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(msg.sender);
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

/**
 * @title ERC20Mintable
 * @dev ERC20 minting logic
 */
contract ERC20Mintable is ERC20, MinterRole {
    /**
     * @dev Function to mint tokens
     * @param to The address that will receive the minted tokens.
     * @param value The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address to, uint256 value) public onlyMinter returns (bool) {
        _mint(to, value);
        return true;
    }
}


/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with ether. This contract implements
 * such functionality in its most fundamental form and can be extended to provide additional
 * functionality and/or custom behavior.
 * The external interface represents the basic interface for purchasing tokens, and conforms
 * the base architecture for crowdsales. It is *not* intended to be modified / overridden.
 * The internal interface conforms the extensible and modifiable surface of crowdsales. Override
 * the methods to add functionality. Consider using 'super' where appropriate to concatenate
 * behavior.
 */
contract Crowdsale is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // The token being sold
    IERC20 private _token;

    // Address where funds are collected
    address payable private _wallet;

    // How many token units a buyer gets per wei.
    // The rate is the conversion between wei and the smallest and indivisible token unit.
    // So, if you are using a rate of 1 with a ERC20Detailed token with 3 decimals called TOK
    // 1 wei will give you 1 unit, or 0.001 TOK.
    uint256 private _rate;

    // Amount of wei raised
    uint256 private _weiRaised;

    /**
     * Event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    /**
     * @param rate Number of token units a buyer gets per wei
     * @dev The rate is the conversion between wei and the smallest and indivisible
     * token unit. So, if you are using a rate of 1 with a ERC20Detailed token
     * with 3 decimals called TOK, 1 wei will give you 1 unit, or 0.001 TOK.
     * @param wallet Address where collected funds will be forwarded to
     * @param token Address of the token being sold
     */
    constructor (uint256 rate, address payable wallet, IERC20 token) public {
        require(rate > 0, "Crowdsale: rate is 0");
        require(wallet != address(0), "Crowdsale: wallet is the zero address");
        require(address(token) != address(0), "Crowdsale: token is the zero address");

        _rate = rate;
        _wallet = wallet;
        _token = token;
    }

    /**
     * @dev fallback function ***DO NOT OVERRIDE***
     * Note that other contracts will transfer funds with a base gas stipend
     * of 2300, which is not enough to call buyTokens. Consider calling
     * buyTokens directly when purchasing tokens from a contract.
     */
    function () external payable {
        buyTokens(msg.sender);
    }

    /**
     * @return the token being sold.
     */
    function token() public view returns (IERC20) {
        return _token;
    }

    /**
     * @return the address where funds are collected.
     */
    function wallet() public view returns (address payable) {
        return _wallet;
    }

    /**
     * @return the number of token units a buyer gets per wei.
     */
    function rate() public view returns (uint256) {
        return _rate;
    }

    /**
     * @return the amount of wei raised.
     */
    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }

    /**
     * @dev low level token purchase ***DO NOT OVERRIDE***
     * This function has a non-reentrancy guard, so it shouldn't be called by
     * another `nonReentrant` function.
     * @param beneficiary Recipient of the token purchase
     */
    function buyTokens(address beneficiary) public nonReentrant payable {
        uint256 weiAmount = msg.value;


        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(weiAmount);

        // update state
        _weiRaised = _weiRaised.add(weiAmount);

        _processPurchase(beneficiary, tokens);
        emit TokensPurchased(msg.sender, beneficiary, weiAmount, tokens);



        _forwardFunds();

    }




    /**
     * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends
     * its tokens.
     * @param beneficiary Address performing the token purchase
     * @param tokenAmount Number of tokens to be emitted
     */
    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal {
        _token.safeTransfer(beneficiary, tokenAmount);
    }

    /**
     * @dev Executed when a purchase has been validated and is ready to be executed. Doesn't necessarily emit/send
     * tokens.
     * @param beneficiary Address receiving the tokens
     * @param tokenAmount Number of tokens to be purchased
     */
    function _processPurchase(address beneficiary, uint256 tokenAmount) internal {
        _deliverTokens(beneficiary, tokenAmount);
    }



    /**
     * @dev Override to extend the way in which ether is converted to tokens.
     * @param weiAmount Value in wei to be converted into tokens
     * @return Number of tokens that can be purchased with the specified _weiAmount
     */
    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return weiAmount.mul(_rate);
    }

    /**
     * @dev Determines how ETH is stored/forwarded on purchases.
     */
    function _forwardFunds() internal {
        _wallet.transfer(msg.value);
    }
}

/**
 * @title TimedCrowdsale
 * @dev Crowdsale accepting contributions only within a time frame.
 */
contract TimedCrowdsale is Crowdsale {
    using SafeMath for uint256;

    uint256 private _openingTime;
    uint256 private _closingTime;

    /**
     * Event for crowdsale extending
     * @param newClosingTime new closing time
     * @param prevClosingTime old closing time
     */
    event TimedCrowdsaleExtended(uint256 prevClosingTime, uint256 newClosingTime);

    /**
     * @dev Reverts if not in crowdsale time range.
     */
    modifier onlyWhileOpen {
        require(isOpen(), "TimedCrowdsale: not open");
        _;
    }

    /**
     * @dev Constructor, takes crowdsale opening and closing times.
     * @param openingTime Crowdsale opening time
     * @param closingTime Crowdsale closing time
     */
    constructor (uint256 openingTime, uint256 closingTime) public {
        // solhint-disable-next-line not-rely-on-time
        require(openingTime >= block.timestamp, "TimedCrowdsale: opening time is before current time");
        // solhint-disable-next-line max-line-length
        require(closingTime > openingTime, "TimedCrowdsale: opening time is not before closing time");

        _openingTime = openingTime;
        _closingTime = closingTime;
    }

    /**
     * @return the crowdsale opening time.
     */
    function openingTime() public view returns (uint256) {
        return _openingTime;
    }

    /**
     * @return the crowdsale closing time.
     */
    function closingTime() public view returns (uint256) {
        return _closingTime;
    }

    /**
     * @return true if the crowdsale is open, false otherwise.
     */
    function isOpen() public view returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp >= _openingTime && block.timestamp <= _closingTime;
    }

    /**
     * @dev Checks whether the period in which the crowdsale is open has already elapsed.
     * @return Whether crowdsale period has elapsed
     */
    function hasClosed() public view returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp > _closingTime;
    }


    /**
     * @dev Extend crowdsale.
     * @param newClosingTime Crowdsale closing time
     */
    function _extendTime(uint256 newClosingTime) internal {
        require(!hasClosed(), "TimedCrowdsale: already closed");
        // solhint-disable-next-line max-line-length
        require(newClosingTime > _closingTime, "TimedCrowdsale: new closing time is before current closing time");

        emit TimedCrowdsaleExtended(_closingTime, newClosingTime);
        _closingTime = newClosingTime;
    }
}

/**
 * @title IncreasingPriceCrowdsale
 * @dev Extension of Crowdsale contract that increases the price of tokens linearly in time.
 * Note that what should be provided to the constructor is the initial and final _rates_, that is,
 * the amount of tokens per wei contributed. Thus, the initial rate must be greater than the final rate.
 */
contract IncreasingPriceCrowdsale is TimedCrowdsale {
    using SafeMath for uint256;

    uint256 private _initialRate;
    uint256 private _finalRate;

    /**
     * @dev Constructor, takes initial and final rates of tokens received per wei contributed.
     * @param initialRate Number of tokens a buyer gets per wei at the start of the crowdsale
     * @param finalRate Number of tokens a buyer gets per wei at the end of the crowdsale
     */
    constructor (uint256 initialRate, uint256 finalRate) public {
        require(finalRate > 0, "IncreasingPriceCrowdsale: final rate is 0");
        // solhint-disable-next-line max-line-length
        require(initialRate > finalRate, "IncreasingPriceCrowdsale: initial rate is not greater than final rate");
        _initialRate = initialRate;
        _finalRate = finalRate;
    }

    /**
     * The base rate function is overridden to revert, since this crowdsale doesn't use it, and
     * all calls to it are a mistake.
     */
    function rate() public view returns (uint256) {
        revert("IncreasingPriceCrowdsale: rate() called");
    }

    /**
     * @return the initial rate of the crowdsale.
     */
    function initialRate() public view returns (uint256) {
        return _initialRate;
    }

    /**
     * @return the final rate of the crowdsale.
     */
    function finalRate() public view returns (uint256) {
        return _finalRate;
    }

    /**
     * @dev Returns the rate of tokens per wei at the present time.
     * Note that, as price _increases_ with time, the rate _decreases_.
     * @return The number of tokens a buyer gets per wei at a given time
     */
    function getCurrentRate() public view returns (uint256) {
        if (!isOpen()) {
            return 0;
        }

        // solhint-disable-next-line not-rely-on-time
        uint256 elapsedTime = block.timestamp.sub(openingTime());
        uint256 timeRange = closingTime().sub(openingTime());
        uint256 rateRange = _initialRate.sub(_finalRate);
        return _initialRate.sub(elapsedTime.mul(rateRange).div(timeRange));
    }

    /**
     * @dev Overrides parent method taking into account variable rate.
     * @param weiAmount The value in wei to be converted into tokens
     * @return The number of tokens _weiAmount wei will buy at present time
     */
    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        uint256 currentRate = getCurrentRate();
        return currentRate.mul(weiAmount);
    }
}
/**
 * @title MintedCrowdsale
 * @dev Extension of Crowdsale contract whose tokens are minted in each purchase.
 * Token ownership should be transferred to MintedCrowdsale for minting.
 */
contract MintedCrowdsale is Crowdsale {
    /**
     * @dev Overrides delivery by minting tokens upon purchase.
     * @param beneficiary Token purchaser
     * @param tokenAmount Number of tokens to be minted
     */
    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal {
        // Potentially dangerous assumption about the type of the token.
        require(
            ERC20Mintable(address(token())).mint(beneficiary, tokenAmount),
                "MintedCrowdsale: minting failed"
        );
    }
}

contract Token is ERC20, ERC20Detailed, ERC20Mintable {

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals
    )
        ERC20Mintable()
        ERC20Detailed(name, symbol, decimals)
        ERC20()
        public
    {}
}


contract MainToken is ERC20, ERC20Detailed, ERC20Mintable {

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals
    )
        ERC20Mintable()
        ERC20Detailed(name, symbol, decimals)
        ERC20()
        public
    {}
}

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

/**
 * @title PaymentSplitter
 * @dev This contract can be used when payments need to be received by a group
 * of people and split proportionately to some number of shares they own.
 */
contract PaymentSplitter {
    using SafeMath for uint256;

    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    uint256 private _totalShares;
    uint256 private _totalReleased;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    address[] private _payees;

    /**
     * @dev Constructor
     */
    constructor (address[] memory payees, uint256[] memory shares) public payable {
        require(payees.length == shares.length);
        require(payees.length > 0);

        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares[i]);
        }
    }

    /**
     * @dev payable fallback
     */
    function () external payable {
        emit PaymentReceived(msg.sender, msg.value);
    }

    /**
     * @return the total shares of the contract.
     */
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    /**
     * @return the total amount already released.
     */
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    /**
     * @return the shares of an account.
     */
    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    /**
     * @return the amount already released to an account.
     */
    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    /**
     * @return the address of a payee.
     */
    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }

    /**
     * @dev Release one of the payee's proportional payment.
     * @param account Whose payments will be released.
     */
    function release(address payable account) public {
        require(_shares[account] > 0);

        uint256 totalReceived = address(this).balance.add(_totalReleased);
        uint256 payment = totalReceived.mul(_shares[account]).div(_totalShares).sub(_released[account]);

        require(payment != 0);

        _released[account] = _released[account].add(payment);
        _totalReleased = _totalReleased.add(payment);

        account.transfer(payment);
        emit PaymentReleased(account, payment);
    }

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param shares_ The number of shares owned by the payee.
     */
    function _addPayee(address account, uint256 shares_) private {
        require(account != address(0));
        require(shares_ > 0);
        require(_shares[account] == 0);

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares.add(shares_);
        emit PayeeAdded(account, shares_);
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     * @notice Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}




contract DSMath {
    /*
    standard uint256 functions
     */

    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assert((z = x + y) >= x);
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assert((z = x - y) <= x);
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assert((z = x * y) >= x);
    }

    function div(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x / y;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x <= y ? x : y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x >= y ? x : y;
    }

    /*
    uint128 functions (h is for half)
     */

    function hadd(uint128 x, uint128 y) internal pure returns (uint128 z) {
        assert((z = x + y) >= x);
    }

    function hsub(uint128 x, uint128 y) internal pure returns (uint128 z) {
        assert((z = x - y) <= x);
    }

    function hmul(uint128 x, uint128 y) internal pure returns (uint128 z) {
        assert((z = x * y) >= x);
    }

    function hdiv(uint128 x, uint128 y) internal pure returns (uint128 z) {
        z = x / y;
    }

    function hmin(uint128 x, uint128 y) internal pure returns (uint128 z) {
        return x <= y ? x : y;
    }

    function hmax(uint128 x, uint128 y) internal pure returns (uint128 z) {
        return x >= y ? x : y;
    }

    /*
    int256 functions
     */

    function imin(int256 x, int256 y) internal pure returns (int256 z) {
        return x <= y ? x : y;
    }

    function imax(int256 x, int256 y) internal pure returns (int256 z) {
        return x >= y ? x : y;
    }

    /*
    WAD math
     */

    uint128 constant WAD = 10 ** 18;

    function wadd(uint128 x, uint128 y) internal pure returns (uint128) {
        return hadd(x, y);
    }

    function wsub(uint128 x, uint128 y) internal pure returns (uint128) {
        return hsub(x, y);
    }

    function wmul(uint128 x, uint128 y) internal pure returns (uint128 z) {
        z = cast((uint256(x) * y + WAD / 2) / WAD);
    }

    function wdiv(uint128 x, uint128 y) internal pure returns (uint128 z) {
        z = cast((uint256(x) * WAD + y / 2) / y);
    }

    function wmin(uint128 x, uint128 y) internal pure returns (uint128) {
        return hmin(x, y);
    }

    function wmax(uint128 x, uint128 y) internal pure returns (uint128) {
        return hmax(x, y);
    }

    /*
    RAY math
     */

    uint128 constant RAY = 10 ** 27;

    function radd(uint128 x, uint128 y) internal pure returns (uint128) {
        return hadd(x, y);
    }

    function rsub(uint128 x, uint128 y) internal pure returns (uint128) {
        return hsub(x, y);
    }

    function rmul(uint128 x, uint128 y) internal pure returns (uint128 z) {
        z = cast((uint256(x) * y + RAY / 2) / RAY);
    }

    function rdiv(uint128 x, uint128 y) internal pure returns (uint128 z) {
        z = cast((uint256(x) * RAY + y / 2) / y);
    }

    function rpow(uint128 x, uint64 n) internal pure returns (uint128 z) {
        // This famous algorithm is called "exponentiation by squaring"
        // and calculates x^n with x as fixed-point and n as regular unsigned.
        //
        // It's O(log n), instead of O(n) for naive repeated multiplication.
        //
        // These facts are why it works:
        //
        //  If n is even, then x^n = (x^2)^(n/2).
        //  If n is odd,  then x^n = x * x^(n-1),
        //   and applying the equation for even x gives
        //    x^n = x * (x^2)^((n-1) / 2).
        //
        //  Also, EVM division is flooring and
        //    floor[(n-1) / 2] = floor[n / 2].

        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }

    function rmin(uint128 x, uint128 y) internal pure returns (uint128) {
        return hmin(x, y);
    }

    function rmax(uint128 x, uint128 y) internal pure returns (uint128) {
        return hmax(x, y);
    }

    function cast(uint256 x) internal pure returns (uint128 z) {
        assert((z = uint128(x)) == x);
    }

}


contract DSAuthority {
    function canCall(address src, address dst, bytes4 sig) public view returns (bool);
}


contract DSAuthEvents {
    event LogSetAuthority(address indexed authority);
    event LogSetOwner(address indexed owner);
}


contract DSAuth is DSAuthEvents {
    DSAuthority public authority;
    address public owner;

    constructor() public {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
    }

    function setOwner(address owner_) public auth {
        owner = owner_;
        emit LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_) public auth {
        authority = authority_;
        emit LogSetAuthority(address(authority));
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig), "It must be an authorized call");
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == DSAuthority(0)) {
            return false;
        } else {
            return authority.canCall(src, address(this), sig);
        }
    }
}



contract DSNote {
    event LogNote(
        bytes4 indexed sig,
        address indexed guy,
        bytes32 indexed foo,
        bytes32 bar,
        uint wad,
        bytes fax
    );

    modifier note {
        bytes32 foo;
        bytes32 bar;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            foo := calldataload(4)
            bar := calldataload(36)
        }

        emit LogNote(
            msg.sig,
            msg.sender,
            foo,
            bar,
            msg.value,
            msg.data
        );

        _;
    }
}



contract DSThing is DSAuth, DSNote, DSMath {}

contract PriceFeed is DSThing {
    uint128 val;
    uint32 public zzz;

    function peek() public view returns (bytes32, bool) {
        return (bytes32(uint256(val)), block.timestamp < zzz);
    }

    function read() public view returns (bytes32) {
        assert(block.timestamp < zzz);
        return bytes32(uint256(val));
    }

    function post(uint128 val_, uint32 zzz_, address med_) public payable note auth {
        val = val_;
        zzz = zzz_;
        (bool success, ) = med_.call(abi.encodeWithSignature("poke()"));
        require(success, "The poke must succeed");
    }

    function void() public payable note auth {
        zzz = 0;
    }

}

contract DSValue is DSThing {
    bool has;
    bytes32 val;
    function peek() public view returns (bytes32, bool) {
        return (val, has);
    }

    function read() public view returns (bytes32) {
        (bytes32 wut, bool _has) = peek();
        assert(_has);
        return wut;
    }

    function poke(bytes32 wut) public payable note auth {
        val = wut;
        has = true;
    }

    function void() public payable note auth {
        // unset the value
        has = false;
    }
}



contract Medianizer is DSValue {
    mapping(bytes12 => address) public values;
    mapping(address => bytes12) public indexes;
    bytes12 public next = bytes12(uint96(1));
    uint96 public minimun = 0x1;

    function set(address wat) public auth {
        bytes12 nextId = bytes12(uint96(next) + 1);
        assert(nextId != 0x0);
        set(next, wat);
        next = nextId;
    }

    function set(bytes12 pos, address wat) public payable note auth {
        require(pos != 0x0, "pos cannot be 0x0");
        require(wat == address(0) || indexes[wat] == 0, "wat is not defined or it has an index");

        indexes[values[pos]] = bytes12(0); // Making sure to remove a possible existing address in that position

        if (wat != address(0)) {
            indexes[wat] = pos;
        }

        values[pos] = wat;
    }

    function setMin(uint96 min_) public payable note auth {
        require(min_ != 0x0, "min cannot be 0x0");
        minimun = min_;
    }

    function setNext(bytes12 next_) public payable note auth {
        require(next_ != 0x0, "next cannot be 0x0");
        next = next_;
    }

    function unset(bytes12 pos) public {
        set(pos, address(0));
    }

    function unset(address wat) public {
        set(indexes[wat], address(0));
    }

    function poke() public {
        poke(0);
    }

    function poke(bytes32) public payable note {
        (val, has) = compute();
    }

    function compute() public view returns (bytes32, bool) {
        bytes32[] memory wuts = new bytes32[](uint96(next) - 1);
        uint96 ctr = 0;
        for (uint96 i = 1; i < uint96(next); i++) {
            if (values[bytes12(i)] != address(0)) {
                (bytes32 wut, bool wuz) = DSValue(values[bytes12(i)]).peek();
                if (wuz) {
                    if (ctr == 0 || wut >= wuts[ctr - 1]) {
                        wuts[ctr] = wut;
                    } else {
                        uint96 j = 0;
                        while (wut >= wuts[j]) {
                            j++;
                        }
                        for (uint96 k = ctr; k > j; k--) {
                            wuts[k] = wuts[k - 1];
                        }
                        wuts[j] = wut;
                    }
                    ctr++;
                }
            }
        }

        if (ctr < minimun)
            return (val, false);

        bytes32 value;
        if (ctr % 2 == 0) {
            uint128 val1 = uint128(uint(wuts[(ctr / 2) - 1]));
            uint128 val2 = uint128(uint(wuts[ctr / 2]));
            value = bytes32(uint256(wdiv(hadd(val1, val2), 2 ether)));
        } else {
            value = wuts[(ctr - 1) / 2];
        }

        return (value, true);
    }
}




contract Settings is Ownable{
        
        using SafeMath for uint256;
    
        event AddContractProposalLog(
            bytes32 indexed hash, 
            address indexed creator, 
            address indexed futureContract, 
            uint256 startDate, 
            uint256 endDate, 
            uint256 activationDate, 
            uint256 expiresIn, 
            string title, 
            string description, 
            string ipfs, 
            string url, 
            uint256 propType);   

        event RemoveContractProposalLog(
            bytes32 indexed hash, 
            address indexed creator, 
            address indexed futureContract, 
            uint256 startDate, 
            uint256 endDate, 
            uint256 activationDate, 
            string description, 
            string ipfs, 
            uint256 propType); 

        event paramProposaLog(
            bytes32 indexed hash, 
            address indexed creator, 
            uint256 param, 
            uint256 value, 
            uint256 startDate, 
            uint256 endDate, 
            uint256 activationDate, 
            string description, 
            uint256 propType);   

        event AddProjectProposalLog(
            bytes32 indexed hash, 
            address indexed creator, 
            uint256 startDate, 
            uint256 endDate, 
            uint256 activationDate, 
            string title, 
            string description, 
            string url, 
            uint256 propType);   

        event ChangePriceFeedProposalLog(
            bytes32 indexed hash, 
            address indexed creator, 
            uint256 startDate, 
            uint256 endDate, 
            uint256 activationDate, 
            string title, 
            string description, 
            uint256 propType);   

        event votedLog(address indexed voter, bool vote, bytes32 indexed hash);
        event addedContractLog(address indexed futureContract);
        event removedContractLog (address indexed futureContract);
        event activatedAddContractProposal (address indexed sender, bytes32 indexed hash);
        
        struct Proposal {
            // general
            uint256 yes;
            uint256 no;
            uint256 totalAccounts;
            uint256 endVotingDate;
            uint256 activationDate;
            uint256 propType;
            bool    activated;
            address creator;

            // future contracts
            uint256 expiresIn;
            uint256 payment;
            address futureContract;

            // params
            uint256 param;
            uint256 value;

            address priceFeedSource;

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
/*         mapping(address => uint256) public blockedAddContractVoting;*/


        mapping(address => uint256) public stakeLockedUntil;
        mapping(address => FContract) public trustedContracts;

        ERC20Mintable mainToken;
        Depository public depository;
        address payable public depositoryAddress;
        address public  priceFeedSource;
        bool public emergencyMode;
        Param[] public params;
        uint256 trustedContractsNum;
        uint256 version;

        
        constructor(
            uint256  _votingTime,
            uint256  _activationIn,
            uint256  _feeLimit,
            uint256  _feeMarket,
            uint256  _maxLeverage,
            uint256  _liquidationProfit,
            uint256  _minVotingPercent,
            uint256  _paramProposalFee,
            uint256  futureContractProposalFee,
            uint256  _feeDiscountIndex,
            uint256  _maxMarketLength,
            uint256  _blockVotingFee,
            address  _mainTokenAddress,
            address  _priceFeedSource
        ) public {
            
            for (uint256 n = 0; n < 12; n++) {
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
            params[8].value = futureContractProposalFee;
            params[9].value = _feeDiscountIndex;
            params[10].value = _maxMarketLength;
            params[11].value = _blockVotingFee;

            priceFeedSource = _priceFeedSource;
            mainToken = MainToken(_mainTokenAddress);
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
            string memory ipfs, 
            string memory url, 
            uint256 payment
        ) public payable {

            require(getContractProposalFee() == msg.value, 'Creator should pay fee.');
            bytes32 hash = sha256(abi.encodePacked(msg.sender, now));

            proposals[hash].endVotingDate = now + getVotingTime();
            proposals[hash].activationDate = now + getVotingTime() + getActivationTime();
            proposals[hash].creator = msg.sender;
            proposals[hash].propType = 0;
            proposals[hash].expiresIn = expiresIn;
            proposals[hash].payment = payment;
            proposals[hash].futureContract = futureContract;

            //depositoryAddress.transfer(msg.value);

            emit AddContractProposalLog(hash, msg.sender, proposals[hash].futureContract, now, proposals[hash].endVotingDate, proposals[hash].activationDate, expiresIn, title, description, ipfs, url, 0);
        }


        function removeContractProposal(
            address futureContract, 
            string memory description, 
            string memory ipfs
        ) public payable {

            require(getContractProposalFee() == msg.value, 'Creator should pay fee.');
            bytes32 hash = sha256(abi.encodePacked(msg.sender, now));

            proposals[hash].endVotingDate = now + getVotingTime();
            proposals[hash].activationDate = now + getVotingTime() + getActivationTime();
            proposals[hash].creator = msg.sender;
            proposals[hash].propType = 1;
            proposals[hash].futureContract = futureContract;

           // depositoryAddress.transfer(msg.value);
            emit RemoveContractProposalLog(hash, msg.sender, proposals[hash].futureContract, now, proposals[hash].endVotingDate, proposals[hash].activationDate, description, ipfs, 1);
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
            proposals[hash].value = value;
            proposals[hash].param = param;
        
            //depositoryAddress.transfer(msg.value);
            emit paramProposaLog(hash, msg.sender, param, value, now, proposals[hash].endVotingDate, proposals[hash].activationDate, description, 2);
        }

        function addProjectProposal(
            string memory title, 
            string memory description, 
            string memory url, 
            uint256 payment
        ) public payable {

            require(getParamProposalFee() == msg.value, 'Creator should pay fee.');
            require (mainToken.totalSupply().div(1000) < payment, 'Requested payment is too large');
            bytes32 hash = sha256(abi.encodePacked(msg.sender, now));

            proposals[hash].endVotingDate = now + getVotingTime();
            proposals[hash].activationDate = now + getVotingTime() + getActivationTime();
            proposals[hash].creator = msg.sender;
            proposals[hash].propType = 3;
            proposals[hash].payment = payment;

            //depositoryAddress.transfer(msg.value);
            emit AddProjectProposalLog(hash, msg.sender, now, proposals[hash].endVotingDate, proposals[hash].activationDate, title, description, url, 3);
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
            emit ChangePriceFeedProposalLog(hash, msg.sender, now, proposals[hash].endVotingDate, proposals[hash].activationDate, title, description, 4);
        }


        function voteProposal(bool vote, bytes32 hash ) public {
            uint256 amount = depository.getStakedFundsOf(msg.sender);
           
            require(amount>0, 'Staked amount should be more then 0.');
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
                    expirationDate: now + proposals[hash].expiresIn,
                    terms: proposals[hash].expiresIn,
                    activationDate: now
                });
                trustedContractsNum = trustedContractsNum.add(1);
                version = version.add(1);
                require(mainToken.mint(proposals[hash].creator, proposals[hash].payment));
                emit addedContractLog (proposals[hash].futureContract);
            }

            if(proposals[hash].propType == 1) { 
                trustedContracts[proposals[hash].futureContract].trusted = false;
                trustedContractsNum = trustedContractsNum.sub(1);
                version = version.add(1);
                emit removedContractLog (proposals[hash].futureContract);
            }

            if(proposals[hash].propType == 2) { 
                params[proposals[hash].param].value = proposals[hash].value;
                params[proposals[hash].param].activationDate = now;
                params[proposals[hash].param].proposalHash = hash;
            }

            if(proposals[hash].propType == 3) { 
                require(mainToken.mint(proposals[hash].creator, proposals[hash].payment));
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
            stakeLockedUntil[msg.sender] = proposals[hash].activationDate;
            blocks[hash] = blocks[hash].add(amount);
            //depositoryAddress.transfer(msg.value);
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


    constructor (
        address _settingsAddress,
        address _tokenAddress,
        address _mainTokenAddress
    ) public payable {
        token = Token(_tokenAddress);
        mainToken = Token(_mainTokenAddress);
        settings = Settings(_settingsAddress);
    }

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

        (bytes32 price, ) = Medianizer(settings.priceFeedSource()).peek();
        //uint256 price = 140000000000000000000; //only for testing purposes
        
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


contract Redeployer {
    constructor () public {}
    function deploy(        
        address _settingsAddress, 
        address payable _depositoryAddress, 
        uint256 _decimal,
        uint256 _maxOrderValue,
        uint256 _minOrderValue,
        uint256 _bancrupcyDiff,
        string memory _ticker,
        uint256 _number
        ) public returns (address){
        FutureContract futureContract = new FutureContract(_settingsAddress, _depositoryAddress, _decimal, _maxOrderValue, _minOrderValue, _bancrupcyDiff, _ticker, _number, address(this));

        return address(futureContract);
    }
}


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




