pragma solidity ^0.4.23;

import "./Ownable.sol";

contract Reclaimable is Ownable {
    function reclaimEther() onlyOwner external {
        owner.transfer(address(this).balance);
    }
}
