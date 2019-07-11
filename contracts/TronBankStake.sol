pragma solidity ^0.4.0;

import "./Pausable.sol";
import "./SimpleToken.sol";
import "./SafeMath.sol";

contract TronBankStake is Pausable{
    using SafeMath for uint256;

    address public tokenAddr;

    uint256 public limit = 2;
    uint256 public totalStake;
    uint256 public overLimitStake;
    uint256 public unfreezingStake;
    uint256[] public tokenHolderLimitArray;

    address[] public tokenHolderArray;
    uint256[] public tokenStakeArray;
    uint256[] public tokenUnfreezingArray;
    uint256[] public lastUnfreezeTime;
    uint256 public unfreezeCd = 86400;//24h
    uint256 public minOperateValue = 1e6;
    mapping(address => uint256) playerToIndexMap;

    event StakeToken(address indexed owner, uint256 stakeValue, uint256 totalValue);
    event UnStakeToken(address indexed owner, uint256 oldUnfreezingValue, uint256 newUnfreezingValue, uint256 leftValue);
    event CancelUnStakeToken(address indexed owner, uint256 cancelValue, uint256 totalValue);
    event WithdrawalToken(address indexed owner, uint256 withdrawalValue);

    function setUnfreezeCd(uint256 cd) onlyOperator public{
        unfreezeCd = cd;
    }

    function setTokenAddr(address addr) onlyOperator public{
        tokenAddr = addr;
    }

    function updateHolderLimit(uint256 _index, uint256 _count, bool _active) onlyOperator public{
        if(_count > 0){
            if(_active){
                if(tokenHolderLimitArray[_index] == 0){
                    overLimitStake = overLimitStake.sub(tokenStakeArray[_index]);
                }
                tokenHolderLimitArray[_index] = tokenHolderLimitArray[_index].add(_count);
            }else{
                tokenHolderLimitArray[_index] = tokenHolderLimitArray[_index].sub(_count);
                if(tokenHolderLimitArray[_index] == 0){
                    overLimitStake = overLimitStake.add(tokenStakeArray[_index]);
                }
            }
        }
    }

    function resetHolderLimit(address _addr) onlyOperator public{
        uint256 index = playerToIndexMap[_addr];
        if(index > 0){
            _resetHolderLimit(index);
        }
    }

    function _resetHolderLimit(uint256 _index) private{
        if(tokenHolderLimitArray[_index] == 0){
            overLimitStake = overLimitStake.sub(tokenStakeArray[_index]);
        }
        tokenHolderLimitArray[_index] = limit;
    }

    function setLimit(uint256 _limit) onlyOperator public{
        limit = _limit;
    }

    function getEffectiveStake() view public returns(uint256){
        return totalStake.sub(overLimitStake);
    }

    function baseAddress(address _addr) onlyOperator public{
        tokenHolderArray[0] = _addr;
    }


    function getStakeInfo() view public returns(uint256 maxIndex, uint256 _totalStake, uint256 _effectiveStake, uint256 _overLimitStake, uint256 _unfreezingStake){
        maxIndex = tokenHolderArray.length;
        _totalStake = totalStake;
        _effectiveStake = totalStake.sub(overLimitStake);
        _overLimitStake = overLimitStake;
        _unfreezingStake = unfreezingStake;
    }

    function getTokenStakeArray(uint256 start, uint256 end) view public returns(uint256[]){
        require(end >= start,"param is invalid");
        uint256[] memory stakeValArray = new uint256[](end.sub(start).add(1));
        for(uint i = 0; i <= stakeValArray.length; i++){
            stakeValArray[i] = tokenStakeArray[i.add(start)];
        }
        return stakeValArray;
    }

    function withdrawalToken(address _tokenAddr, uint256 value) onlyOwner public{
        SimpleToken t = SimpleToken(_tokenAddr);
        require(t.transfer(msg.sender, value));
    }

    function withdrawal(uint256 value) onlyOperator public returns(bool){
        return msg.sender.send(value);
    }

    function setMinOperateValue(uint256 value) onlyOperator public{
        minOperateValue = value;
    }

    function getStakeInfoByAddr(address addr) view public returns(address owner,uint256 tokenValue,uint256 tmUnfreeze, uint256 unfreezing, uint256 nowLimit){
        uint256 index = playerToIndexMap[addr];
        owner = addr;
        tokenValue = tokenStakeArray[index];
        tmUnfreeze = lastUnfreezeTime[index];
        unfreezing = tokenUnfreezingArray[index];
        nowLimit = tokenHolderLimitArray[index];
    }

    function receiveApproval(address staker, uint256 value,address addr, bytes extraData) whenNoPaused public{
        require(addr == tokenAddr, "token address is invalid");
        SimpleToken t = SimpleToken(tokenAddr);
        require(value >= minOperateValue,"value too small");
        require(t.transferFrom(staker, this, value),"transferFrom failed");
        uint256 index = playerToIndexMap[staker];
        if(index == 0){
            playerToIndexMap[staker] = tokenHolderArray.push(staker) - 1;
            tokenStakeArray.push(value);
            tokenUnfreezingArray.push(0);
            lastUnfreezeTime.push(0);
            tokenHolderLimitArray.push(limit);
        }else{
            require(tokenHolderArray[index] == staker,"address not match");
            _resetHolderLimit(index);
            tokenStakeArray[index] = tokenStakeArray[index].add(value);
        }
        totalStake = totalStake.add(value);
        emit StakeToken(staker, value, totalStake);
    }

    function unfreezingBalance() view public returns(uint256){
        uint256 index = playerToIndexMap[msg.sender];
        return tokenUnfreezingArray[index];
    }

    function getTokenStakeByIndex(uint256 index) view public returns(address owner, uint256 stakeValue, uint256 _limit){
        owner = tokenHolderArray[index];
        stakeValue = tokenStakeArray[index];
        _limit = tokenHolderLimitArray[index];
    }

    function withdrawalUnfrozen() public{
        uint256 index = playerToIndexMap[msg.sender];
        require(index > 0 && tokenHolderArray[index] == msg.sender,"index is invalid");
        require(tokenUnfreezingArray[index] > 0,"nothing to withdrawal");
        require(now >= lastUnfreezeTime[index] + unfreezeCd,"withdrawal is cooling");
        uint256 value = tokenUnfreezingArray[index];
        tokenUnfreezingArray[index] = 0;
        unfreezingStake = unfreezingStake.sub(value);
        SimpleToken t = SimpleToken(tokenAddr);
        require(t.transfer(msg.sender, value),"transfer token failed");
        emit WithdrawalToken(msg.sender, value);
    }

    function cancelUnfreeze() whenNoPaused public{
        uint256 index = playerToIndexMap[msg.sender];
        require(index > 0 && tokenHolderArray[index] == msg.sender);
        uint256 value = tokenUnfreezingArray[index];
        require(value > 0, "nothing to cancel unfreeze");
        tokenUnfreezingArray[index] = 0;
        unfreezingStake = unfreezingStake.sub(value);
        totalStake = totalStake.add(value);
        if(tokenHolderLimitArray[index] == 0){
            overLimitStake = overLimitStake.add(value);
        }
        tokenStakeArray[index] = tokenStakeArray[index].add(value);
        emit CancelUnStakeToken(msg.sender, value, tokenStakeArray[index]);
    }

    function unfreeze(uint256 value) whenNoPaused public{
        require(value >= minOperateValue,"value too small");
        uint256 index = playerToIndexMap[msg.sender];
        require(index > 0 && tokenHolderArray[index] == msg.sender);
        require(value <= tokenStakeArray[index],"bigger than stake");
        uint256 oldUnfreezingValue = tokenUnfreezingArray[index];
        totalStake = totalStake.sub(value);
        if(tokenHolderLimitArray[index] == 0){
            overLimitStake = overLimitStake.sub(value);
        }
        tokenStakeArray[index] = tokenStakeArray[index].sub(value);
        tokenUnfreezingArray[index] = tokenUnfreezingArray[index].add(value);
        unfreezingStake = unfreezingStake.add(value);
        lastUnfreezeTime[index] = now;
        emit UnStakeToken(msg.sender, oldUnfreezingValue, tokenUnfreezingArray[index], tokenStakeArray[index]);
    }


    function () payable public{
        revert();
    }

    constructor () public {
        tokenStakeArray.push(0);
        tokenHolderLimitArray.push(0);
        tokenHolderArray.push(address(0));
        tokenUnfreezingArray.push(0);
        lastUnfreezeTime.push(0);
    }
}