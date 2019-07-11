pragma solidity ^0.4.0;

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
    address public owner;

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

    function transferOwnership(address newOwner) onlyOwner public {
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
        return operatorMap[_addr] || _addr == owner;
    }
}

interface IGasCalcable{
    function guessFeeWithCountView(uint256 slicecount) external pure returns (uint256);
}

contract SimpleCalcGas is IGasCalcable{
    using SafeMath for uint256;
    uint256 public unitPrice = 10000;

    function guessFeeWithCountView(uint256 slicecount) public view returns (uint256){
        return calcGasByCnt(slicecount);
    }

    function calcGasByCnt(uint256 slicecount) internal view returns (uint256 gas){
        gas = slicecount.mul(unitPrice);
    }
}

contract RedEnvelopes is Operatable, SimpleCalcGas{
    address public feeOwner;
    using SafeMath for uint256;
    event UnitPriceChange(uint256 price);
    event GrabToken(address indexed tokenaddr, address indexed toaddr, uint256 value);
    event GrabTRX(address indexed fromaddr, address indexed toaddr, uint256 indexed value);
    event RefundToken(address indexed tokenaddr, address indexed toaddr, uint256 value);
    event RefundTRX(address indexed toaddr, uint256 refundcount, uint256 indexed value);
    function setUnitPrice(uint256 price) onlyOperator public returns(uint256){
        unitPrice = price;
        emit UnitPriceChange(unitPrice);
        return unitPrice;
    }

    function setFeeOwner(address fee) onlyOperator public returns(address){
        feeOwner = fee;
        return feeOwner;
    }

    function getBalance() onlyOperator public view returns(uint256){
        return address(this).balance;
    }

    function withdrawal(uint256 value) onlyOperator public returns(bool){
        return msg.sender.send(value);
    }

    function withdrawalAll() onlyOperator public returns(bool){
        return msg.sender.send(address(this).balance);
    }

    function grabToken(address tokenaddr, address toaddr, uint256 value) onlyOperator public returns(bool transferResult){
        Token t = Token(tokenaddr);
        transferResult = t.transfer(toaddr, value);
        require(transferResult);
        emit GrabToken(tokenaddr, toaddr, value);
    }

    function grabTRX(address fromaddr, address toaddr, uint256 value) onlyOperator public returns(bool transferResult){
        transferResult = toaddr.send(value);
        require(transferResult);
        emit GrabTRX(fromaddr, toaddr, value);
    }

    function refundTRX(address toaddr, uint256 refundcount, uint256 value) onlyOperator payable public returns(bool transferResult){
        uint256 fee = value.add(msg.value);
        transferResult = toaddr.send(fee);
        require(transferResult);
        emit RefundTRX(toaddr, refundcount, value);
    }

    function withdrawalToken(address tokenaddr, address toaddr, uint256 value) onlyOperator public returns(bool transferResult){
        Token t = Token(tokenaddr);
        transferResult = t.transfer(toaddr, value);
        require(transferResult);
        emit RefundToken(tokenaddr, toaddr, value);
    }

    bool public isOpen = true;

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

    function packageToken(uint256 slicecount) payable onlyOpen public returns(bool){
        uint256 fee = guessFeeWithCountView(slicecount);
        require(fee > 0 && fee <= msg.value);
        require(feeOwner.send(msg.value));
        return true;
    }

    function packageTRX(uint256 value, uint256 slicecount) payable onlyOpen public returns(bool){
        uint256 fee = guessFeeWithCountView(slicecount);
        uint256 payValue = fee.add(value);
        require(fee > 0 && payValue <= msg.value);
        require(feeOwner.send(fee));
        return true;
    }
    function () public {
        revert();
    }
    constructor() public {
        feeOwner = owner;
    }
}
