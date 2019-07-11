pragma solidity ^0.4.0;

import "./Pausable.sol";
import "./SimpleToken.sol";
import "./SafeMath.sol";

contract KKStake is Pausable{
    using SafeMath for uint256;
    address public tokenAddr;
    uint256 public totalStake;
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


    function getStakeInfo() view public returns(uint256 maxIndex, uint256 _totalStake){
        maxIndex = tokenHolderArray.length;
        _totalStake = totalStake;
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

    function getStakeInfoByAddr(address addr) view public returns(address owner,uint256 tokenValue,uint256 tmUnfreeze, uint256 unfreezing){
        uint256 index = playerToIndexMap[addr];
        owner = addr;
        tokenValue = tokenStakeArray[index];
        tmUnfreeze = lastUnfreezeTime[index];
        unfreezing = tokenUnfreezingArray[index];
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
        }else{
            require(tokenHolderArray[index] == staker,"address not match");
            tokenStakeArray[index] = tokenStakeArray[index].add(value);
        }
        totalStake = totalStake.add(value);
        emit StakeToken(staker, value, totalStake);
    }

    function unfreezingBalance() view public returns(uint256){
        uint256 index = playerToIndexMap[msg.sender];
        return tokenUnfreezingArray[index];
    }

    function getTokenStakeByIndex(uint256 index) view public returns(address owner, uint256 stakeValue){
        owner = tokenHolderArray[index];
        stakeValue = tokenStakeArray[index];
    }

    function withdrawalUnfrozen() public{
        uint256 index = playerToIndexMap[msg.sender];
        require(index > 0 && tokenHolderArray[index] == msg.sender,"index is invalid");
        require(tokenUnfreezingArray[index] > 0,"nothing to withdrawal");
        require(now >= lastUnfreezeTime[index] + unfreezeCd,"withdrawal is cooling");
        uint256 value = tokenUnfreezingArray[index];
        tokenUnfreezingArray[index] = 0;
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
        totalStake = totalStake.add(value);
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
        tokenStakeArray[index] = tokenStakeArray[index].sub(value);
        tokenUnfreezingArray[index] = tokenUnfreezingArray[index].add(value);
        lastUnfreezeTime[index] = now;
        emit UnStakeToken(msg.sender, oldUnfreezingValue, tokenUnfreezingArray[index], tokenStakeArray[index]);
    }


    function () payable public{
        revert();
    }

    constructor () public {
        tokenStakeArray.push(0);
        tokenHolderArray.push(address(0));
        tokenUnfreezingArray.push(0);
        lastUnfreezeTime.push(0);
    }
}