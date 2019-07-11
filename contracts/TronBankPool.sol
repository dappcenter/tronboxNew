pragma solidity ^0.4.0;

import "./SimpleToken.sol";
import "./Pausable.sol";
import "./SafeMath.sol";
library Objects {
    struct OtherPlan {
        bool isValid;
        address planAddress;
        uint256 extraBonus;
        uint256 rate;
        uint256 profit;
        bool active;
    }
}
contract TronBankPool is Pausable {
    using SafeMath for uint256;
    address public tokenAddr;

    uint256 public baseTrxValue;

    uint256 public totalMintTrx;

    uint256 public miningTokenRate = 0;

    uint256 public baseMiningTokenRate = 1000;

    uint256 public baseIncreaseUnit = 20;

    uint256 public perStageToken = 1000000e6;

    uint256 public convertUnit = 1e3;

    uint256 public lastOperateBalance;

    bool public lastOperateActive;

    Objects.OtherPlan[] otherPlanArray;

    function addBaseTrx() payable public returns(uint256){
        baseTrxValue = baseTrxValue.add(msg.value);
        (lastOperateBalance, lastOperateActive) = calculateAddProfit(lastOperateBalance, lastOperateActive, msg.value, true);
        return baseTrxValue;
    }

    function withdrawalBaseTrx(uint256 value) onlyOperator public returns(uint256){
        require(value <= baseTrxValue,"bigger than balance");
        baseTrxValue = baseTrxValue.sub(value);
        (lastOperateBalance, lastOperateActive) = calculateSubProfit(lastOperateBalance, lastOperateActive, value, true);
        require(msg.sender.send(value));
        return baseTrxValue;
    }

    function withdrawalProfit() public returns(uint256 _profit, bool _active){
        for(uint256 i = 0; i < otherPlanArray.length; i++){
            if(otherPlanArray[i].isValid && otherPlanArray[i].planAddress == msg.sender){
                (_profit, _active) = withdrawalProfitInner(i);
                break;
            }
        }
    }

    function setConvertUnit(uint256 _unit) onlyOperator public {
        convertUnit = _unit;
    }

    function addOtherPlan(address _planAddress, uint256 _rate, bool _isValid) onlyOperator public returns(uint256 _index){
        _index = otherPlanArray.push(Objects.OtherPlan({isValid : _isValid, planAddress : _planAddress, extraBonus : 0, rate : _rate, profit : 0, active : false})) - 1;
    }

    function updateOtherPlanByAddr(address _planAddress, uint256 _rate, bool _isValid) onlyOperator public returns(uint256 _index){
        for(uint256 i = 0 ; i < otherPlanArray.length; i++){
            if(otherPlanArray[i].planAddress == _planAddress){
                otherPlanArray[i].isValid = _isValid;
                otherPlanArray[i].rate = _rate;
                break;
            }
        }
    }

    function setOtherPlanExpired(uint256 _index, bool _isValid) onlyOperator public{
        otherPlanArray[_index].isValid = _isValid;
    }

    function updateOtherPlanByIndex(uint256 _index, address _planAddress, uint256 _rate, bool _isValid) onlyOperator public{
        otherPlanArray[_index].planAddress = _planAddress;
        otherPlanArray[_index].isValid = _isValid;
        otherPlanArray[_index].rate = _rate;
    }

    function getOtherPlanLength() view public returns(uint256 planLength){
        planLength = otherPlanArray.length;
    }

    function getOtherPlan(uint256 _index) view public returns(bool _isValid, address _planAddress, uint256 _extraBonus, uint256 _rate, uint256 _profit, bool _active){
        require(_index < otherPlanArray.length);
        _isValid = otherPlanArray[_index].isValid;
        _planAddress = otherPlanArray[_index].planAddress;
        _extraBonus = otherPlanArray[_index].extraBonus;
        _rate = otherPlanArray[_index].rate;
        _profit = otherPlanArray[_index].profit;
        _active = otherPlanArray[_index].active;
    }

    function addOtherPlanProfit(uint256 _index) payable public returns(uint256 _profit, bool _active){
        require(msg.value > 0);
        otherPlanArray[_index].extraBonus = otherPlanArray[_index].extraBonus.add(msg.value);
        (lastOperateBalance, lastOperateActive) = calculateAddProfit(lastOperateBalance, lastOperateActive, msg.value, true);
        (_profit, _active) = getCurrentProfitExtraInner(_index);
    }

    function addOtherPlanProfit(address _addr) payable public returns(uint256 _profit, bool _active){
        require(msg.value > 0);
        for(uint256 i = 0; i < otherPlanArray.length; i++){
            if(otherPlanArray[i].isValid && otherPlanArray[i].planAddress == _addr){
                otherPlanArray[i].extraBonus = otherPlanArray[i].extraBonus.add(msg.value);
                (lastOperateBalance, lastOperateActive) = calculateAddProfit(lastOperateBalance, lastOperateActive, msg.value, true);
                (_profit, _active) = getCurrentProfitExtraInner(i);
                break;
            }
        }
    }

    function getCurrentProfitInner(uint256 _index, uint256 _tempProfit, bool _tempActive) private view returns(uint256 _profit, bool _active){
        (_profit, _active) = calculateAddProfit(otherPlanArray[_index].profit, otherPlanArray[_index].active, calculateRate(_tempProfit,otherPlanArray[_index].rate), _tempActive);
    }

    function getCurrentProfitExtraInner(uint256 _index) private view returns(uint256 _profit, bool _active){
        (_profit, _active) = getTempProfitInfo();
        (_profit, _active) = getCurrentProfitInner(_index, _profit, _active);
        if(_active){
            (_profit, _active) = calculateAddProfit(_profit, _active , otherPlanArray[_index].extraBonus, true);
        }else{
            if(otherPlanArray[_index].extraBonus > 0){
                _profit = otherPlanArray[_index].extraBonus;
                _active = true;
            }
        }
    }

    function getCurrentProfitByIndex(uint256 _index) public view returns(uint256 _profit, bool _active){
        (_profit, _active) = getCurrentProfitExtraInner(_index);
    }

    function getTempProfitInfo() private view returns(uint256 _profit, bool _active){
        (_profit, _active) = calculateSubProfit(address(this).balance, true, lastOperateBalance, lastOperateActive);
    }

    function resetLastOperateInfo() private returns(uint256 _profit, bool _active){
        uint256 nowBalance = address(this).balance;
        (_profit, _active) = calculateSubProfit(nowBalance, true, lastOperateBalance, lastOperateActive);
        lastOperateBalance = nowBalance;
        lastOperateActive = true;
    }

    function calculateAddProfit(uint256 _nowProfit, bool _nowActive, uint256 _profit, bool _active) pure private returns(uint256 _reProfit, bool _reActive){
        if(_active == _nowActive){
            _reProfit = _nowProfit.add(_profit);
            _reActive = _active;
        }else{
            if(_nowProfit > _profit){
                _reProfit = _nowProfit.sub(_profit);
                _reActive = _nowActive;
            }else{
                _reProfit = _profit.sub(_nowProfit);
                _reActive = _active;
            }
            if(_reProfit == 0){
                _reActive = false;
            }
        }
    }

    function calculateRate(uint256 _profit, uint256 _rate) view private returns(uint256 _rateProfit){
        _rateProfit = _profit.mul(_rate).div(convertUnit);
    }

    function calculateSubProfit(uint256 _nowProfit, bool _nowActive, uint256 _profit, bool _active) pure private returns(uint256 _reProfit, bool _reActive){
        (_reProfit, _reActive) = calculateAddProfit(_nowProfit, _nowActive, _profit, !_active);
    }

    function clearOtherPlanByIndex(uint256 _index) private{
        otherPlanArray[_index].profit = 0;
        otherPlanArray[_index].active = false;
        otherPlanArray[_index].extraBonus = 0;
    }

    function lastOperateChange(uint256 _value, bool _active) private{
        (lastOperateBalance, lastOperateActive) = calculateAddProfit(lastOperateBalance, lastOperateActive, _value, _active);
    }

    function withdrawalProfitInner(uint256 _index) private returns(uint256 _profit, bool _active){
        (_profit, _active) = resetLastOperateInfo();
        for(uint256 i = 0; i < otherPlanArray.length; i++){
            if(otherPlanArray[i].isValid){
                (otherPlanArray[i].profit, otherPlanArray[i].active) = getCurrentProfitInner(i, _profit, _active);
            }
        }
        _profit = otherPlanArray[_index].profit;
        _active = otherPlanArray[_index].active;
        if(_active){
            (_profit, _active) = calculateAddProfit(_profit, _active , otherPlanArray[_index].extraBonus, true);
            require(msg.sender.send(_profit),"transfer failed");
            lastOperateChange(_profit, false);
        }else{
            baseTrxValue = baseTrxValue.sub(_profit);
            if(otherPlanArray[_index].extraBonus > 0){
                _profit = otherPlanArray[_index].extraBonus;
                require(msg.sender.send(_profit),"transfer failed");
                lastOperateChange(_profit, false);
                _active = true;
            }
        }
        clearOtherPlanByIndex(_index);
    }

    function withdrawalProfitByIndex(uint256 _index) onlyOperator public returns(uint256 _profit, bool _active){
        (_profit, _active) = withdrawalProfitInner(_index);
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

    function getCurrentProfit() public view returns(uint256 _profit,bool _active){
        for(uint256 i = 0; i < otherPlanArray.length; i++){
            if(otherPlanArray[i].isValid && otherPlanArray[i].planAddress == msg.sender){
                (_profit, _active) = getCurrentProfitExtraInner(i);
                break;
            }
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