pragma solidity ^0.4.22;

interface ISafeERC20 {
    function safeTransfer(address _token, address _to, uint256 _value) external returns (bool);
    
    function safeTransferFrom(address _token, address _from, address _to, uint256 _value) external returns (bool);
    
    function safeApprove(address _token, address _spender, uint256 _value) external returns (bool);
}
