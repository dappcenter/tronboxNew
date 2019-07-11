pragma solidity >=0.4.22 <0.6.0;

import "./DWPausable.sol";
library Objects {
    struct Vote {
        string name;
        string value;
        string unit;
        string remark;
        uint256 status;
        uint256 pre;
        uint256 later;
        uint256[] certificateArray;
    }
}
contract DWVote  is DWPausable{
    address public recordAddr;
    address public certAddr;

    function () payable external{
    }

    constructor () public {
    }
}
