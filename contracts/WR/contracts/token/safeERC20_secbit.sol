/*

badERC20 POC Fix by SECBIT Team

USE WITH CAUTION & NO WARRANTY

REFERENCE & RELATED READING
- https://github.com/ethereum/solidity/issues/4116
- https://medium.com/@chris_77367/explaining-unexpected-reverts-starting-with-solidity-0-4-22-3ada6e82308c
- https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
- https://gist.github.com/BrendanChou/88a2eeb80947ff00bcf58ffdafeaeb61

*/

pragma solidity ^0.4.24;

import "./ERC20.sol";
import "./ISafeERC20.sol";

library ERC20AsmFn {

    function isContract(address addr) internal {
        assembly {
            if iszero(extcodesize(addr)) { revert(0, 0) }
        }
    }

    function handleReturnData() internal returns (bool result) {
        assembly {
            switch returndatasize()
            case 0 { // not a std erc20
                result := 1
            }
            case 32 { // std erc20
                returndatacopy(0, 0, 32)
                result := mload(0)
            }
            default { // anything else, should revert for safety
                revert(0, 0)
            }
        }
    }

    function asmTransfer(address _erc20Addr, address _to, uint256 _value) internal returns (bool result) {

        // Must be a contract addr first!
        isContract(_erc20Addr);
        
        // call return false when something wrong
        require(_erc20Addr.call(bytes4(keccak256("transfer(address,uint256)")), _to, _value));
        
        // handle returndata
        return handleReturnData();
    }

    function asmTransferFrom(address _erc20Addr, address _from, address _to, uint256 _value) internal returns (bool result) {

        // Must be a contract addr first!
        isContract(_erc20Addr);

        // call return false when something wrong
        require(_erc20Addr.call(bytes4(keccak256("transferFrom(address,address,uint256)")), _from, _to, _value));
        
        // handle returndata
        return handleReturnData();
    }

    function asmApprove(address _erc20Addr, address _spender, uint256 _value) internal returns (bool result) {

        // Must be a contract addr first!
        isContract(_erc20Addr);

        // call return false when something wrong
        require(_erc20Addr.call(bytes4(keccak256("approve(address,uint256)")), _spender, _value));
        
        // handle returndata
        return handleReturnData();
    }
}

contract SafeERC20 is ISafeERC20{

    using ERC20AsmFn for ERC20;

    function safeTransfer(address _token, address _to, uint256 _value) public returns (bool) {
        return ERC20(_token).asmTransfer(_to, _value);
    }

    function safeTransferFrom(address _token, address _from, address _to, uint256 _value) public returns (bool){
        return ERC20(_token).asmTransferFrom(_from, _to, _value);
    }

    function safeApprove(address _token, address _spender, uint256 _value) public returns (bool){
        return ERC20(_token).asmApprove(_spender, _value);
    }
}
