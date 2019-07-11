pragma solidity ^0.4.23;

import "./Operatable.sol";


contract KKSeed is Operatable {
    mapping(address => bytes32) seedMap;
    bytes32 commonSeed;
    function getSeed(address target) view public returns(bytes32){
        bytes32 temp = seedMap[target];
        if(keccak256(abi.encodePacked(temp)) == keccak256(abi.encodePacked(bytes32(0)))){
            temp = commonSeed;
        }
        return temp;
    }

    function getMySeed() view public returns(bytes32){
        return getSeed(msg.sender);
    }

    function setCommonSeed(bytes32 seed) onlyOperator public{
        commonSeed = seed;
    }

    function setMySeed(bytes32 seed) public{
        seedMap[msg.sender] = seed;
    }

    function () payable public{
        revert();
    }

    constructor () public {
        commonSeed = sha256(abi.encodePacked(now));
    }
}
