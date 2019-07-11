pragma solidity ^0.4.0;

import "./SimpleToken.sol";
import "./Pausable.sol";
import "./SafeMath.sol";

contract BaseTrc20Pool is Pausable {
    using SafeMath for uint256;

    address public tokenAddr;

    uint256 public baseValue;

    function receiveApproval(address sender, uint256 value,address addr, bytes extraData) whenNoPaused public{
        require(addr == tokenAddr, "token address is invalid");
        SimpleToken t = SimpleToken(tokenAddr);
        require(t.transferFrom(sender, this, value),"transferFrom failed");
        baseValue = baseValue.add(value);
    }

    function withdrawalTrx(uint256 value) onlyOperator public returns(uint256){
        require(msg.sender.send(value));
    }

    function withdrawalBaseValue(uint256 value) onlyOperator public returns(uint256){
        require(value <= baseValue,"bigger than balance");
        baseValue = baseValue.sub(value);
        SimpleToken t = SimpleToken(tokenAddr);
        require(t.transfer(msg.sender, value),"transfer failed");
        return baseValue;
    }

    function withdrawalProfit() onlyOperator public returns(uint256 _profit, bool _active){
        SimpleToken t = SimpleToken(tokenAddr);
        uint256 _balance = t.balanceOf(address(this));
        if(_balance > baseValue){
            _profit = _balance.sub(baseValue);
            _active = true;
            require(t.transfer(msg.sender, _profit),"transfer failed");
        }else{
            _profit = baseValue.sub(_balance);
            baseValue = baseValue.sub(_profit);
            _active = false;
        }
    }

    function getCurrentProfit() public view returns(uint256 profit,bool active){
        SimpleToken t = SimpleToken(tokenAddr);
        uint256 _balance = t.balanceOf(address(this));
        if(_balance > baseValue){
            active = true;
            profit = _balance.sub(baseValue);
        }else{
            active = false;
            profit = baseValue.sub(_balance);
        }
    }

    function getStatus() view public returns(uint256 nowBalance, uint256 base){
        SimpleToken t = SimpleToken(tokenAddr);
        uint256 _balance = t.balanceOf(address(this));
        nowBalance = _balance;
        base = baseValue;
    }

    function setTokenAddr(address addr) onlyOperator public{
        tokenAddr = addr;
    }

    function () public payable{

    }

    constructor() public{

    }
}