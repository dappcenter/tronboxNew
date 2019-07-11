pragma solidity >=0.4.22 <0.6.0;
import "./WROperatable.sol";

contract WRPausable is WROperatable{
    bool public paused = false;

    modifier whenPaused{
        require(paused);
        _;
    }

    modifier whenNoPaused{
        require(!paused);
        _;
    }

    function doPause() external onlyCLevel whenNoPaused{
        paused = true;
    }

    function doUnPause() external onlyCLevel whenPaused{
        paused = false;
    }

}
