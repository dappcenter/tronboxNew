pragma solidity ^0.4.0;

import "./SimpleToken.sol";
import "./Pausable.sol";
import "./SafeMath.sol";

contract KKPool is Pausable {
    using SafeMath for uint256;
    address public tokenAddr;

    uint256 public baseTrxValue;

    uint256 public totalMintTrx;

    uint256 public miningTokenRate = 0;

    uint256 public baseMiningTokenRate = 1000;

    uint256 public baseIncreaseUnit = 20;

    uint256 public perStageToken = 1000000e6;

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

    function withdrawalProfit() onlyOperator public returns(uint256 _profit, bool _active){
        if(address(this).balance > baseTrxValue){
            _profit = address(this).balance.sub(baseTrxValue);
            _active = true;
            require(msg.sender.send(_profit),"transfer failed");
        }else{
            _profit = baseTrxValue.sub(address(this).balance);
            baseTrxValue = baseTrxValue.sub(_profit);
            _active = false;
        }
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
        if(address(this).balance > baseTrxValue){
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

    function setTokenAddr(address addr) onlyOperator public{
        tokenAddr = addr;
    }

    function setMiningTokenRate(uint256 value) onlyOperator public{
        miningTokenRate = value;
    }

    function setTotalMintTrx(uint256 value) onlyOperator public{
        totalMintTrx = value;
    }

    function setBaseMiningTokenRate(uint256 value) onlyOperator public{
        baseMiningTokenRate = value;
    }

    function setBaseIncreaseUnit(uint256 value) onlyOperator public{
        baseIncreaseUnit = value;
    }

    function setPerStageToken(uint256 value) onlyOperator public{
        perStageToken = value;
    }

    function transferTrx(address to, uint256 value) onlyOperator public{
        require(to.send(value),"transfer failed");
    }

    function transferTrx2(address to1, uint256 value1, address to2, uint256 value2) onlyOperator public{
        require(to1.send(value1) && to2.send(value2),"transfer failed");
    }

    function getNowMintRate() view public returns(uint256 nowRate){
        if(miningTokenRate > 0){
            nowRate = miningTokenRate;
        }else{
            SimpleToken t = SimpleToken(tokenAddr);
            uint256 mintedValue = t.getMintedValue();
            nowRate = baseMiningTokenRate.add(mintedValue.div(perStageToken).mul(baseIncreaseUnit));
        }
    }

    function () public payable{
        if(isOperator(msg.sender)){
            totalMintTrx = totalMintTrx.add(msg.value);
            SimpleToken t = SimpleToken(tokenAddr);
            if(miningTokenRate > 0){
                require(t.mint(1, tx.origin, msg.value, miningTokenRate));
            }else{
                uint256 mintedValue = t.getMintedValue();
                require(t.mint(1, tx.origin, msg.value, baseMiningTokenRate.add(mintedValue.div(perStageToken).mul(baseIncreaseUnit))));
            }
        }
    }

    constructor() public{
    }
}