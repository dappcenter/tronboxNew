pragma solidity ^0.4.0;
import "./Ownable.sol";
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
