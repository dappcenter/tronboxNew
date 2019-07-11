pragma solidity ^0.4.0;

import "./Pausable.sol";
import "./SafeMath.sol";

contract BaseTrc10Pool is Pausable {
    using SafeMath for uint256;
    uint256 public tokenId;

    uint256 public baseValue;

    function addBaseValue() payable public returns(uint256){
        require(msg.tokenid == tokenId, "Wrong token id");
        baseValue = baseValue.add(msg.tokenvalue);
        return baseValue;
    }

    function addProfitValue() payable public returns(uint256){
        require(msg.tokenid == tokenId, "Wrong token id");
        return msg.tokenvalue;
    }

    function withdrawalTrx(uint256 value) onlyOperator public returns(uint256){
        require(msg.sender.send(value));
    }

    function withdrawalBaseValue(uint256 value) onlyOperator public returns(uint256){
        require(value <= baseValue,"bigger than balance");
        baseValue = baseValue.sub(value);
        msg.sender.transferToken(value, tokenId);
        return baseValue;
    }

    function withdrawalProfit() onlyOperator public returns(uint256 _profit, bool _active){
        if(address(this).tokenBalance(tokenId) > baseValue){
            _profit = address(this).tokenBalance(tokenId).sub(baseValue);
            _active = true;
            msg.sender.transferToken(_profit, tokenId);
        }else{
            _profit = baseValue.sub(address(this).tokenBalance(tokenId));
            baseValue = baseValue.sub(_profit);
            _active = false;
        }
    }

    function getCurrentProfit() public view returns(uint256 profit,bool active){
        if(address(this).tokenBalance(tokenId) > baseValue){
            active = true;
            profit = address(this).tokenBalance(tokenId).sub(baseValue);
        }else{
            active = false;
            profit = baseValue.sub(address(this).tokenBalance(tokenId));
        }
    }

    function getStatus() view public returns(uint256 nowBalance, uint256 base){
        nowBalance = address(this).tokenBalance(tokenId);
        base = baseValue;
    }

    function setTokenId(uint256 _tokenId) onlyOperator public{
        tokenId = _tokenId;
    }

    function () public payable{

    }

    constructor() public{

    }
}