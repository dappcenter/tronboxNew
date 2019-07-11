pragma solidity ^0.4.0;

import "./Operatable.sol";

contract Pausable is Operatable{
    bool public paused = false;

    modifier whenPaused{
        require(paused);
        _;
    }

    modifier whenNoPaused{
        require(!paused);
        _;
    }

    function doPause() external onlyOperator whenNoPaused{
        paused = true;
    }

    function doUnPause() external onlyOperator whenPaused{
        paused = false;
    }
}
