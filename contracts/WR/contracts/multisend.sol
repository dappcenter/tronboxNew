pragma solidity ^0.4.23;

contract Token {
    /* This is a slight change to the ERC20 base standard.
    function totalSupply() constant returns (uint256 supply);
    is replaced with:
    uint256 public totalSupply;
    This automatically creates a getter function for the totalSupply.
    This is moved to the base contract since public getter functions are not
    currently recognised as an implementation of the matching abstract
    function by the compiler.
    */
    /// total amount of tokens
    uint256 public totalSupply;

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant public returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) public returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) public returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant public returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
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
        return operatorMap[_addr] || msg.sender == owner;
    }
}

interface IGasCalcable{
    function guessGasWithValue(address tokenaddr, uint256 toCnt, uint256 valuePerOne) external returns (uint256);
    
    function guessGasView(address tokenaddr, uint256 toCnt, uint256 valuePerOne, uint256 gasprice) public pure returns (uint256);
    
    function guessGasWithValues(address tokenaddr, uint256 toCnt, uint256 ttvalue) external returns (uint256);
    
    function guessGasWithValuesView(address tokenaddr, uint256 toCnt, uint256 ttvalue,uint256 gasprice) public pure returns (uint256);
}

contract SimpleCalcGas is IGasCalcable{
    
   function guessGasWithValue(address _addr, uint256 toCnt, uint256 v) public returns (uint256){
       return guessGasView(_addr,toCnt,v, tx.gasprice);
   }
   
   function guessGasView(address , uint256 toCnt, uint256 ,uint256 gasprice) public pure returns (uint256){
       return calcGasByCntAndGasPrice(toCnt, gasprice);
   }
   
   function guessGasWithValues(address _addr, uint256 toCnt, uint256 v ) public returns (uint256){
       return guessGasWithValuesView(_addr,toCnt, v, tx.gasprice);
   }
   
   function guessGasWithValuesView(address tokenaddr, uint256 toCnt, uint256 ttvalue,uint256 gasprice) public pure returns (uint256){
       return calcGasByCntAndGasPrice(toCnt, gasprice);
   }
   
   function calcGasByCntAndGasPrice(uint256 cnt, uint256 price) internal pure returns (uint256 gas){
       gas = cnt * price * 10000;
   }
}

contract MultiSender is Operatable, SimpleCalcGas{
   
   function multiTransfer(address tokenaddr, address[] tos, uint256 value) onlyOperator public {
       Token t = Token(tokenaddr);
       for (uint256 i = 0; i < tos.length; i++) {
           t.transferFrom(msg.sender,tos[i],value);
       }
   }
   
   function multiTransferValues(address tokenaddr, address[] tos, uint256[] value) onlyOperator public {
       Token t = Token(tokenaddr);
       for (uint256 i = 0; i < tos.length; i++) {
           t.transferFrom(msg.sender,tos[i],value[i]);
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
   
   function getCalcContract() onlyOwner view public returns(address) {
       return calcContract;
   }
   
   function setCalcContract(address _contract) onlyOwner public {
       calcContract = IGasCalcable(_contract);
   }
   
   function multiTransferToken(address tokenaddr, address[] tos, uint256 value) payable onlyOpen public returns( bool ) {
       uint256 gas = calcContract.guessGasWithValue(tokenaddr, tos.length, value);
       if (!owner.send(gas)) return false;
       Token t = Token(tokenaddr);
       for (uint256 i = 0; i < tos.length; i++) {
           t.transferFrom(msg.sender,tos[i],value);
       }
       return true;
   }
   
   function multiTransferTokenValues(address tokenaddr, address[] tos, uint256[] value) payable onlyOpen public returns( bool ) {
       uint256 tt = 0;
       for(uint vi=0; vi< value.length; ++vi){
           tt = tt + value[vi];
       }
       require(tt > 0);
       uint256 gas = calcContract.guessGasWithValues(tokenaddr, tos.length, tt);
       if (!owner.send(gas)) return false;
       Token t = Token(tokenaddr);
       for (uint256 i = 0; i < tos.length; i++) {
           t.transferFrom(msg.sender,tos[i],value[i]);
       }
       return true;
   }
   
   constructor() public {
   }
}
