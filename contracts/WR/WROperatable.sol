pragma solidity >=0.4.22 <0.6.0;
import "./WROwnable.sol";
contract WROperatable is WROwnable {
    mapping (address => bool) operatorMap;

    address public ceoAddress;
    address public cfoAddress;
    address public cooAddress;

    modifier onlyCEO() {
        require(msg.sender == ceoAddress || msg.sender == owner);
        _;
    }

    modifier onlyCFO() {
        require(msg.sender == cfoAddress || msg.sender == owner);
        _;
    }

    modifier onlyCOO() {
        require(msg.sender == cooAddress || msg.sender == owner);
        _;
    }

    modifier onlyCLevel() {
        require(
            msg.sender == cooAddress ||
            msg.sender == ceoAddress ||
            msg.sender == cfoAddress ||
            msg.sender == owner
        );
        _;
    }

    function setCEO(address _newCEO) external onlyCEO {
        require(_newCEO != address(0));

        ceoAddress = _newCEO;
    }

    function setCFO(address _newCFO) external onlyCEO {
        require(_newCFO != address(0));

        cfoAddress = _newCFO;
    }

    function setCOO(address _newCOO) external onlyCEO {
        require(_newCOO != address(0));

        cooAddress = _newCOO;
    }

    modifier onlyOperator() {
        require(operatorMap[msg.sender] || msg.sender == cooAddress ||
        msg.sender == ceoAddress ||
        msg.sender == cfoAddress ||
        msg.sender == owner);
        _;
    }

    event OperatorChanged(address indexed operator, bool allow);

    function addOperator(address _addr) onlyCLevel public {
        operatorMap[_addr] = true;
        emit OperatorChanged(_addr, true);
    }

    function addOperators(address[] memory _addrs) onlyCLevel public {
        for (uint256 i = 0; i < _addrs.length; i++) {
            address _addr = _addrs[i];
            operatorMap[_addr] = true;
            emit OperatorChanged(_addr, true);
        }
    }

    function delOperator(address _addr) onlyCLevel public {
        operatorMap[_addr] = false;
        emit OperatorChanged(_addr, false);
    }

    function delOperators(address[] memory _addrs) onlyCLevel public {
        for (uint256 i = 0; i < _addrs.length; i++) {
            address _addr = _addrs[i];
            operatorMap[_addr] = false;
            emit OperatorChanged(_addr, false);
        }
    }

    function isOperator(address _addr) view public returns (bool) {
        return operatorMap[_addr] || _addr == cooAddress ||
        _addr == ceoAddress ||
        _addr == cfoAddress ||
        _addr == owner;
    }

    function isCLevel(address _addr) view public returns (bool) {
        return _addr == cooAddress ||
        _addr == ceoAddress ||
        _addr == cfoAddress ||
        _addr == owner;
    }

    constructor() public {
        ceoAddress = msg.sender;
        cfoAddress = msg.sender;
        cooAddress = msg.sender;
    }
}
