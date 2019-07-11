pragma solidity ^0.4.0;

import "./SimpleToken.sol";
import "./Pausable.sol";
import "./SafeMath.sol";

contract KKPoolOld is Pausable {
    using SafeMath for uint256;
    address public tokenAddr;
    uint256 public tokenDecimal;
    uint256 private tokenPoolBalance;//init equals token.balanceOf(this)
    address public devAddr;
    mapping(address => uint256) public miningValue;
    uint256 public baseTrxValue;

    uint256 public miningTokenRate;
    uint256 public devReleaseRate;
    uint256 public releaseConvertUnit = 1e4;

    function addBaseTrx() payable public returns(uint256){
        baseTrxValue = baseTrxValue.add(msg.value);
        return baseTrxValue;
    }

    function withdrawalBaseTrx(uint256 value) onlyOperator public returns(uint256){
        require(value <= baseTrxValue,"bigger than balance");
        baseTrxValue = baseTrxValue.sub(value);
        require(msg.sender.send(value));
        return baseTrxValue;
    }

    function withdrawalProfit() onlyOperator public returns(uint256){
        require(address(this).balance > baseTrxValue,"bigger than balance");
        uint256 profit = address(this).balance.sub(baseTrxValue);
        require(msg.sender.send(profit),"transfer failed");
        return profit;
    }

    function withdrawalToken(address _tokenAddr, uint256 value) onlyOwner public{
        SimpleToken t = SimpleToken(_tokenAddr);
        require(t.transfer(msg.sender, value),"transfer failed");
    }

    function transferToken(address _tokenAddr, address to, uint256 value) onlyOwner public{
        SimpleToken t = SimpleToken(_tokenAddr);
        require(t.transfer(to, value),"transfer failed");
    }

    function transferToken2(address _tokenAddr, address to1, uint256 value1, address to2, uint256 value2) onlyOwner public{
        SimpleToken t = SimpleToken(_tokenAddr);
        require(t.transfer(to1, value1),"transfer failed");
        require(t.transfer(to2, value2),"transfer failed");
    }

    function getCurrentProfit() public view returns(uint256 profit,bool active){
        if(address(this).balance >= baseTrxValue){
            active = true;
            profit = address(this).balance.sub(baseTrxValue);
        }else{
            active = false;
            profit = baseTrxValue.sub(address(this).balance);
        }
    }

    function getStatus() view public returns(uint256 nowBalance, uint256 base){
        nowBalance = address(this).balance;
        base = baseTrxValue;
    }

    function setTokenAddr(address addr, uint256 decimals) onlyOperator public{
        tokenAddr = addr;
        tokenDecimal = decimals;
    }

    function releaseTokenAll() public {
        SimpleToken t = SimpleToken(tokenAddr);
        uint256 value = miningValue[msg.sender];
        require(value > 0,"nothing to release");
        miningValue[msg.sender] = 0;
        require(t.transfer(msg.sender, miningValue[msg.sender]));
    }

    function releaseToken(uint256 value) public {
        uint256 nowValue = miningValue[msg.sender];
        require(nowValue >= value,"bigger than balance");
        SimpleToken t = SimpleToken(tokenAddr);
        miningValue[msg.sender] = nowValue.sub(value);
        require(t.transfer(msg.sender, value),"transfer failed");
    }

    function releaseDevToken() onlyOperator public{
        SimpleToken t = SimpleToken(tokenAddr);
        miningValue[devAddr] = 0;
        require(t.transfer(devAddr, miningValue[devAddr]),"transfer failed");
    }

    function setMiningTokenRate(uint256 value) onlyOperator public{
        miningTokenRate = value;
    }

    function setDevReleaseRate(uint256 value) onlyOperator public{
        devReleaseRate = value;
    }

    function setReleaseConvertUnit(uint256 value) onlyOperator public{
        releaseConvertUnit = value;
    }

    function setDevAddr(address addr) onlyOperator public{
        devAddr = addr;
    }

    function transferTrx(address to, uint256 value) onlyOperator public{
        require(to.send(value),"transfer failed");
    }

    function transferTrx2(address to1, uint256 value1, address to2, uint256 value2) onlyOperator public{
        require(to1.send(value1) && to2.send(value2),"transfer failed");
    }

    function getTokenPoolBalance() view public returns(uint256){
        return tokenPoolBalance;
    }

    function initTokenPoolBalance(uint256 initBalance) onlyOwner public{
        tokenPoolBalance = initBalance;
    }

    function () public payable{
        if(isOperator(msg.sender) && tokenPoolBalance > 0){
            uint256 bettorMining = msg.value.mul(10**tokenDecimal).div(miningTokenRate);
            uint256 devRelease = bettorMining.mul(devReleaseRate).div(releaseConvertUnit);
            tokenPoolBalance = tokenPoolBalance.sub(bettorMining).sub(devRelease);
            miningValue[tx.origin] = miningValue[tx.origin].add(bettorMining);
            miningValue[devAddr] = miningValue[devAddr].add(devRelease);
        }
    }

    constructor(address _tokenAddress, uint256 _decimal, uint256 _miningTokenRate, address _devAddr,
        uint256 _tokenPoolBalance, uint256 _devReleaseRate) public{
        tokenAddr = _tokenAddress;
        tokenDecimal = _decimal;
        miningTokenRate = _miningTokenRate;
        devAddr = _devAddr;
        tokenPoolBalance = _tokenPoolBalance;
        devReleaseRate = _devReleaseRate;
    }
}