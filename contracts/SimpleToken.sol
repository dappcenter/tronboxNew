pragma solidity ^0.4.0;

contract SimpleToken {

    function totalSupply() public view returns (uint);

    function balanceOf(address tokenOwner) public view returns (uint balance);

    function allowance(address tokenOwner, address spender) view public returns (uint remaining);

    function transfer(address to, uint tokens) public returns (bool success);

    function approve(address spender, uint tokens) public returns (bool success);

    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    function getMintedValue() view public returns(uint256);
    function mint(uint256 _type, address _to, uint256 _amount, uint256 _mintRate) public returns (bool);
    function burn(uint256 _value) public;
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
