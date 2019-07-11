pragma solidity ^0.4.23;

import "../../ownership/Reclaimable.sol";
import "../ERC20.sol";

contract ERC20Reclaimable is Reclaimable {
    function reclaimToken(address _tokenAddress) onlyOwner external {
        ERC20 token = ERC20(_tokenAddress);
        uint256 balance = token.balanceOf(this);
        token.transfer(owner, balance);
    }
}
