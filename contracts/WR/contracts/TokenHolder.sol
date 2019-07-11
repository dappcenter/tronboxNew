pragma solidity ^0.4.23;

import "./math/SafeMath.sol";
import "./ownership/ClaimableOwnable.sol";
import "./lifecycle/Destructible.sol";
import "./token/ERC20/ERC20Reclaimable.sol";
import "./token/safeERC20_secbit.sol";


contract Operatable is Ownable {
    mapping (address => bool) operatorMap;

    modifier onlyOperator() {
        require(operatorMap[msg.sender] || msg.sender == owner);
        _;
    }

    event OperatorChanged(address indexed operator, bool allow);

    function addOperator(address _addr) onlyOwner public {
        operatorMap[_addr] = true;
        emit OperatorChanged(_addr, true);
    }
    
    function addOperators(address[] _addrs) onlyOwner public {
        for (uint256 i = 0; i < _addrs.length; i++) {
            address _addr = _addrs[i];
            operatorMap[_addr] = true;
            emit OperatorChanged(_addr, true);
        }
    }

    function delOperator(address _addr) onlyOwner public {
        operatorMap[_addr] = false;
        emit OperatorChanged(_addr, false);
    }
    
    function delOperators(address[] _addrs) onlyOwner public {
        for (uint256 i = 0; i < _addrs.length; i++) {
            address _addr = _addrs[i];
            operatorMap[_addr] = false;
            emit OperatorChanged(_addr, false);
        }
    }

    function isOperator(address _addr) view public returns (bool) {
        return operatorMap[_addr];
    }
}

contract TokenHolder is Destructible, ClaimableOwnable, ERC20Reclaimable, Operatable, SafeERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) tokenAllowanceMap;

    event TokenAllowanceChanged(address indexed tokenAddress, uint256 allowance);

    function setTokenAllowance(address _tokenAddress, uint256 _allowance)
    onlyOwner
    external {
        tokenAllowanceMap[_tokenAddress] = _allowance;
        emit TokenAllowanceChanged(_tokenAddress, _allowance);
    }

    function tokenAllowance(address _tokenAddress)
    view
    public
    returns (uint256 allowance) {
        return tokenAllowanceMap[_tokenAddress];
    }

    address[] public defaultTokens;

    event DefaultTokenChanged(address indexed _tokenAddress, bool allowed);

    function addDefaultToken(address _tokenAddress, uint256 _allowance)
    onlyOwner
    external {
        for (uint256 i = 0; i < defaultTokens.length; i++) {
            if (_tokenAddress == defaultTokens[i]) return;
        }
        defaultTokens.push(_tokenAddress);
        emit DefaultTokenChanged(_tokenAddress, true);
        if (_allowance > 0) {
            tokenAllowanceMap[_tokenAddress] = _allowance;
            emit TokenAllowanceChanged(_tokenAddress, _allowance);
        }
    }

    function delDefaultToken(address _tokenAddress)
    onlyOwner
    external {
        for (uint256 i = 0; i < defaultTokens.length; i++) {
            if (_tokenAddress != defaultTokens[i]) continue;

            uint256 lastIndex = defaultTokens.length - 1;
            if (i < lastIndex) defaultTokens[i] = defaultTokens[lastIndex];
            delete defaultTokens[lastIndex];
            defaultTokens.length --;

            emit DefaultTokenChanged(_tokenAddress, false);
            return;
        }
    }

    address[] public defaultHolders;

    event AllowedHolderChanged(address indexed _holder, bool allowed);

    function addHolder(address _holder) onlyOwner public {
        for (uint256 i = 0; i < defaultHolders.length; i++) {
            if (_holder == defaultHolders[i]) return;
        }
        defaultHolders.push(_holder);
        emit AllowedHolderChanged(_holder, true);
    }
    
    function addHolders(address[] _holders) onlyOwner public {
        for (uint256 i = 0; i < _holders.length; i++) {
            address _holder = _holders[i];
            addHolder(_holder);
        }
    }

    function delHolder(address _holder) onlyOwner public {
        for (uint256 i = 0; i < defaultHolders.length; i++) {
            if (_holder != defaultHolders[i]) continue;

            uint256 lastIndex = defaultHolders.length - 1;
            if (i < lastIndex) defaultHolders[i] = defaultHolders[lastIndex];
            delete defaultHolders[lastIndex];
            defaultHolders.length --;

            emit AllowedHolderChanged(_holder, false);
            return;
        }
    }
    
    function delHolders(address[] _holders) onlyOwner public {
        for (uint256 i = 0; i < _holders.length; i++) {
            address _holder = _holders[i];
            delHolder(_holder);
        }
    }

    event TokenTransferred(
        address indexed tokenAddress,
        address indexed holderAddress,
        uint256 amount);

    event TokenInsufficient(
        address indexed tokenAddress,
        address indexed holderAddress,
        uint256 shortage);

    function feedAll()
    onlyOperator
    external {
        for (uint256 i = 0; i < defaultTokens.length; i++) {
            address tokenAddress = defaultTokens[i];
            uint256 allowance = tokenAllowanceMap[tokenAddress];

            _feedHolders(tokenAddress, allowance);
        }
    }

    function feedHolders(address _tokenAddress, uint256 _watermark)
    onlyOperator
    external {

        uint256 allowance = tokenAllowanceMap[_tokenAddress];
        require(allowance >= _watermark);

        _feedHolders(_tokenAddress, _watermark);
    }
    //for badTokens like BNB.
     ISafeERC20 public implementContract = this;
    
    
    function _feedHolders(address _tokenAddress, uint256 _watermark)
    internal {

        ERC20 token = ERC20(_tokenAddress);
        uint256 balance = token.balanceOf(this);

        for (uint256 i = 0; i < defaultHolders.length; i++) {
            address holder = defaultHolders[i];

            uint256 holderBalance = token.balanceOf(holder);
            if (holderBalance >= _watermark) continue;
            uint256 wanted = _watermark - holderBalance;
            if (balance < wanted) {
                emit TokenInsufficient(
                    _tokenAddress,
                    holder,
                    _watermark - holderBalance - balance);
                continue;
            }
            if (implementContract.safeTransfer(_tokenAddress, holder, wanted)) {
                balance -= wanted;
                emit TokenTransferred(
                    _tokenAddress,
                    holder,
                    wanted);
            }
        }
    }
    
    function changeSafeERC20Impl(address impl) public onlyOwner{
        ERC20AsmFn.isContract(impl);
        implementContract = ISafeERC20(impl);
    }
    
    function needFeedHolders(address _tokenAddress) onlyOperator public view returns (uint cnt, address[10] holders){
        uint256 allowance = tokenAllowanceMap[_tokenAddress];
        return needFeedHolders(_tokenAddress, allowance);
    }
    
    function needFeedHolders(address _tokenAddress, uint256 _watermark) onlyOperator public view returns (uint cnt, address[10] holders){
        ERC20 token = ERC20(_tokenAddress);
        for (uint256 i = 0; i < defaultHolders.length; i++) {
            address holder = defaultHolders[i];
            uint256 holderBalance = token.balanceOf(holder);
            if (holderBalance >= _watermark) continue;
            holders[cnt] = holder;
            cnt = cnt + 1;
            if (cnt > 10) break;
        }
    }
}
