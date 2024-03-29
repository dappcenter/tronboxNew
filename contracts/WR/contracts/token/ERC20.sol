pragma solidity ^0.4.23;

/**
 * @title ERC20
 * @dev required interface of ERC20
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
contract ERC20 {
    function totalSupply() view public returns (uint256);

    function balanceOf(address _owner) view public returns (uint256 balance);

    function transfer(address _to, uint256 _value) public returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);

    function allowance(address _owner, address _spender) view public returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
