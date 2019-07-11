pragma solidity ^0.4.23;

import "./ERC20.sol";

/**
 * @title ERC20Detailed
 * @dev optional interface of ERC20
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
contract ERC20Detailed is ERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;

    constructor(string _name, string _symbol, uint8 _decimals) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }
}
