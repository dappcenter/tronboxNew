pragma solidity ^0.4.23;

import "../ownership/Ownable.sol";

contract Destructible is Ownable {
    function destroy() onlyOwner external {
        selfdestruct(owner);
    }
}
