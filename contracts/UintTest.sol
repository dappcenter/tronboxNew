pragma solidity ^0.4.23;

contract UintTest{

    uint256 public  i = 1024;
    mapping(address => uint256) public miningValue;
    mapping(uint256 => address[]) public indexToOwners;
    function getI() view public returns(uint256){
        return i;
    }

    function isSame(bytes _i) view public returns(bool _b){
        _b = (keccak256(abi.encodePacked(toBytes(i))) == keccak256(abi.encodePacked(_i)));
    }

    function toBytes(uint256 x) pure public returns (bytes b) {
        b = new bytes(32);
        assembly { mstore(add(b, 32), x) }
    }

    function getIBytes() view public returns(bytes){
        return toBytes(i);
    }
    function () public payable{

    }

    constructor() public{
    }
}
