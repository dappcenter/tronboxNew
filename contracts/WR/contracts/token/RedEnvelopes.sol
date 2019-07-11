pragma solidity ^0.5.0;

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
        uint256 c = a / b;
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
contract Token {

    function totalSupply() public view returns (uint);

    function balanceOf(address tokenOwner) public view returns (uint balance);

    function allowance(address tokenOwner, address spender) view public returns (uint remaining);

    function transfer(address to, uint tokens) public returns (bool success);

    function approve(address spender, uint tokens) public returns (bool success);

    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
contract Ownable {
    address payable public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function transferOwnership(address payable newOwner) onlyOwner public {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

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

    function addOperators(address[] memory _addrs) onlyOwner public {
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

    function delOperators(address[] memory _addrs) onlyOwner public {
        for (uint256 i = 0; i < _addrs.length; i++) {
            address _addr = _addrs[i];
            operatorMap[_addr] = false;
            emit OperatorChanged(_addr, false);
        }
    }

    function isOperator(address _addr) view public returns (bool) {
        return operatorMap[_addr] || msg.sender == owner;
    }
}

interface IGasCalcable{
    function guessFeeWithCountView(address fromaddr, uint256 slicecount) external pure returns (uint256);
}

contract SimpleCalcGas is IGasCalcable{
    using SafeMath for uint256;
    uint256 public unitPrice = 10000;
    // mapping (address => uint256) vipUnitPrice;
    // event VipUnitPriceChanged(address indexed vipaddr, uint256 price, bool isVip);

    // function addVip(address addr, uint256 price) onlyOperator public {
    //     vipUnitPrice[addr] = price;
    //     emit VipUnitPriceChanged(addr, price, true);
    // }

    // function addVips(address[] memory addrs, uint256[] memory prices) onlyOperator public {
    //     require(addrs.length == prices.length);
    //     for (uint256 i = 0; i < addrs.length; i++) {
    //         address addr = addrs[i];
    //         uint256 price = prices[i];
    //         vipUnitPrice[addr] = price;
    //         emit VipUnitPriceChanged(addr, price, true);
    //     }
    // }

    // function delVip(address addr) onlyOperator public {
    //     delete vipUnitPrice[addr];
    //     emit VipUnitPriceChanged(addr, unitPrice, false);
    // }

    // function delOperators(address[] memory addrs) onlyOperator public {
    //     for (uint256 i = 0; i < addrs.length; i++) {
    //         address addr = addrs[i];
    //         delete vipUnitPrice[addr];
    //         emit VipUnitPriceChanged(addr, unitPrice, false);
    //     }
    // }

    // function isVip(address addr) view public returns (bool) {
    //     return vipUnitPrice[addr] == 0;
    // }

    function guessFeeWithCountView(uint256 slicecount) public view returns (uint256){
        return calcGasByCnt(slicecount);
    }

    function calcGasByCnt(uint256 slicecount) internal view returns (uint256 gas){
        gas = slicecount.mul(unitPrice);
    }
}

contract RedEnvelopes is Operatable, SimpleCalcGas{
    using SafeMath for uint256;
    event UnitPriceChange(uint256 price);
    event GrabToken(address indexed tokenaddr, address indexed fromaddr, address indexed toaddr, uint256 value);
    event GrabTRX(address indexed fromaddr, address indexed toaddr, uint256 indexed value);

    function setUintPrice(uint256 price) onlyOperator public returns(uint256){
        unitPrice = price;
        emit UnitPriceChange(unitPrice);
        return unitPrice;
    }

    function withdrawal(uint256 value) onlyOperator public returns(bool){
        return msg.sender.send(value);
    }

    function withdrawalAll() onlyOperator public returns(bool){
        return msg.sender.send(address(this).balance);
    }

    function grabToken(address tokenaddr, address fromaddr, address toaddr, uint256 value) onlyOperator public returns(bool transferResult){
        Token t = Token(tokenaddr);
        transferResult = t.transferFrom(fromaddr, toaddr, value);
        if(transferResult){
            emit GrabToken(tokenaddr, fromaddr, toaddr, value);
        }
    }

    function grabTRX(address fromaddr, address payable toaddr, uint256 value) onlyOperator public returns(bool transferResult){
        transferResult = toaddr.send(value);
        if(transferResult){
            emit GrabTRX(fromaddr, toaddr, value);
        }
    }

    bool public isOpen = false;

    modifier onlyOpen(){
        require(isOpen);
        _;
    }

    function setOpen() onlyOwner public {
        isOpen = true;
    }

    function setClose() onlyOwner public {
        isOpen = false;
    }

    IGasCalcable calcContract = this;

    function getCalcContract() onlyOwner view public returns(IGasCalcable) {
        return calcContract;
    }

    function setCalcContract(address _contract) onlyOwner public {
        calcContract = IGasCalcable(_contract);
    }

    function packageToken(address tokenaddr, uint256 value, uint256 slicecount) payable onlyOpen public returns(bool){
        uint256 fee = calcContract.guessFeeWithCountView(msg.sender, slicecount);
        require(fee > 0 && fee <= msg.value);
        Token t = Token(tokenaddr);
        uint256 remaining = t.allowance(msg.sender, address(this));
        uint256 approvalValue = remaining.add(value);
        return t.approve(address(this), approvalValue);
    }

    function packageTRX(uint256 value, uint256 slicecount) payable onlyOpen public returns(bool){
        uint256 fee = calcContract.guessFeeWithCountView(msg.sender, slicecount);
        uint256 payValue = fee.add(value);
        require(fee > 0 && payValue <= msg.value);
        return true;
    }

    constructor() public {
    }
}
