pragma solidity >=0.4.22 <0.6.0;
import "./WROperatable.sol";

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Manageable is WROperatable{
    address public admin;
    uint256 public constant decimals = 6;
    uint256 public totalSupply = 100000000000 * (10 ** 6); //

    uint256 public constant MINT_RATE = 60;
    uint256 public constant ANGEL_RATE = 10; //
    uint256 public constant FUND_RATE = 12; // 12% Fund
    uint256 public constant DEV_RATE = 15; // 15% for Dev
    uint256 public constant EARLY_AWARD_RATE = 3; //3% for early award

    address public mintAccount = 0x0695632ccdfc649cbeef4c4f53c2cdbc2d834a42;
    address public angelAccount = 0x0b64de11f7d4744cd721efb6c5449ca9be852287;
    address public fundAccount = 0xbe5c7055a8cf2283d641d35937aac220f39e901a;
    address public devAccount =0x8ed2738daeaf08ca3127948fec79c4a6afd78191;
    address public earlyAwardAccount = 0xe5605e7129ee701dd3b90a2fc616747fd974a78e;

    bool public locked = false;

    constructor() public {
        admin = msg.sender;
        mintAccount = msg.sender;
        angelAccount = msg.sender;
        fundAccount = msg.sender;
        devAccount = msg.sender;
        earlyAwardAccount = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == owner || msg.sender == admin);
        _;
    }
    modifier OnlyCanTransfer(address _to) {
        require(!locked || isOperator(msg.sender) || isOperator(_to),"the token is locking,can't transfer");
        _;
    }

    function setLock(bool _value) onlyOwner public {
        locked = _value;
    }

    function setAdminAccount(address _addr) public onlyOwner {
        require(_addr != address(0));
        admin = _addr;
    }

    function setMintAccount(address _addr) public onlyOwner {
        require(_addr != address(0));
        mintAccount = _addr;
    }

    function setAngelAccount(address _addr) public onlyOwner {
        require(_addr != address(0));
        angelAccount = _addr;
    }

    function setFundAccount(address _addr) public onlyOwner {
        require(_addr != address(0));
        fundAccount = _addr;
    }

    function setDevAccount(address _addr) public onlyOwner {
        require(_addr != address(0));
        devAccount = _addr;
    }

    function setEarlyAwardAccount(address _addr) public onlyOwner {
        require(_addr != address(0));
        earlyAwardAccount = _addr;
    }
}

contract ERC20Interface {

    function balanceOf(address tokenOwner) public view returns (uint balance);

    function allowance(address tokenOwner, address spender) public view returns (uint remaining);

    function transfer(address to, uint tokens) public returns (bool success);

    function approve(address spender, uint tokens) public returns (bool success);

    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


contract ERC20Token is ERC20Interface, Manageable {
    using SafeMath for uint256;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) internal allowed;

    function transfer(address _to, uint256 _value) OnlyCanTransfer(_to) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transferFrom(address _from, address _to, uint256 _value) OnlyCanTransfer(_to) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        require(allowed[msg.sender][_spender] == 0);
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}

contract ApproveAndCallFallBack {
    function receiveApproval(address _from, uint256 _amount, address _token, bytes calldata _data) external;
}

contract GID is ERC20Token {
string public name = "Global Identity";
string public symbol = "GID";
string public version = "1.0";

event onBurn(address indexed _from, address indexed _operator, uint256 _amount);

function() payable external {
revert();
}

constructor() public {
balances[mintAccount] = totalSupply * MINT_RATE / 100;
balances[angelAccount] = totalSupply * ANGEL_RATE / 100;
balances[fundAccount] = totalSupply * FUND_RATE / 100;
balances[devAccount] = totalSupply * DEV_RATE / 100;
balances[earlyAwardAccount] = totalSupply * EARLY_AWARD_RATE / 100;
}

/* Approves and then calls the receiving contract */
function approveAndCall(address _spender, uint256 _value, bytes memory _extraData) public returns (bool success) {
allowed[msg.sender][_spender] = _value;
emit Approval(msg.sender, _spender, _value);

ApproveAndCallFallBack(_spender).receiveApproval(msg.sender, _value, address(this), _extraData);
return true;
}

function burn(uint256 _value) public {
require(_value <= balances[msg.sender]);
address burner = msg.sender;
balances[burner] = balances[burner].sub(_value);
totalSupply = totalSupply.sub(_value);
emit onBurn(burner, address(0), _value);
}

function burnFrom(address _from, uint256 _value) onlyAdmin public{
require(_value <= balances[_from]);
balances[_from] = balances[_from].sub(_value);
totalSupply = totalSupply.sub(_value);
emit onBurn(_from, msg.sender, _value);
}
}