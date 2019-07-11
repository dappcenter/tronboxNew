pragma solidity ^0.4.0;

import "./Pausable.sol";
import "./SafeMath.sol";
import "./SimpleToken.sol";
contract SimplePool{
    function withdrawalProfit() public returns(uint256, bool);
    function getCurrentProfit() view public returns(uint256,bool);
}

contract SimpleStake{
    function getStakeInfo() view public returns(uint256 maxIndex, uint256 _totalStake);
    function doPause() external;
    function doUnPause() external;
    function getTokenStakeByIndex(uint256 index) view public returns(address owner, uint256 stakeValue);
}

library Objects {
    struct Divide10Plan {
        bool isExpired;
        uint256 trc10Id;
        uint256 totalProfit;
        bool active;
        address tokenPoolAddr;
        uint256 divideUnit;
        mapping(address => uint256) tokenBalance;
        mapping(address => uint256) alreadyWithdrawal;
    }
    struct Divide20Plan{
        bool isExpired;
        address trc20Addr;
        uint256 totalProfit;
        bool active;
        address tokenPoolAddr;
        uint256 divideUnit;
        mapping(address => uint256) tokenBalance;
        mapping(address => uint256) alreadyWithdrawal;
    }
}
//TODO trc10 Pool和trc20 Pool的合约
contract TNTDivide is Pausable{
    using SafeMath for uint256;
    address public poolAddr;
    address public stakeAddr;
    Objects.Divide10Plan[] public divide10PlanArray;
    Objects.Divide20Plan[] public divide20PlanArray;
    uint256 maxIndex;
    uint256 currentIndex;
    uint256 totalStake;
    uint256 totalProfit;
    bool active;
    uint256 divideUnit;
    uint256 public divideNum = 0;//分红次数
    uint256 public convertUnit = 1e4;
    mapping(address => uint256) trxBalance;
    mapping(address => uint256) alreadyWithdrawal;
    event DivideComplete(uint256 divideNum, uint256 maxIndex, uint256 totalStake, uint256 totalProfit);

    event DivideStep(uint256 divideNum, uint256 maxIndex, uint256 currentIndex, address addr,
        uint256 divideTrx, uint256 stakeValue, uint256 totalStake, uint256 totalProfit);

    event DivideStep10(uint256 divideNum, uint256 maxIndex, uint256 currentIndex, address addr, uint256 tokenId,
        uint256 divideValue, uint256 stakeValue, uint256 totalStake, uint256 totalProfit);

    event DivideStep20(uint256 divideNum, uint256 maxIndex, uint256 currentIndex, address addr, address tokenAddr,
        uint256 divideValue, uint256 stakeValue, uint256 totalStake, uint256 totalProfit);
    event WithdrawalAll(address indexed addr, uint256 trxValue, uint256 tokenId, address tokenAddr, uint256 tokenValue);

    function withdrawalTrx(uint256 value) onlyOperator public returns(uint256){
        require(value <= address(this).balance);
        require(msg.sender.send(value));
        return value;
    }

    function withdrawalToken10(uint256 _tokenId, uint256 value) onlyOperator public{
        msg.sender.transferToken(value, _tokenId);
    }

    function withdrawalToken20(address _tokenAddr, uint256 value) onlyOperator public{
        SimpleToken t = SimpleToken(_tokenAddr);
        require(t.transfer(msg.sender, value));
    }

    function setByIndex10(uint256 _index, bool _isExpired, address _tokenPoolAddr) onlyOperator public{
        divide10PlanArray[_index].isExpired = _isExpired;
        if(_tokenPoolAddr != address(0)){
            divide10PlanArray[_index].tokenPoolAddr = _tokenPoolAddr;
        }
    }

    function setByIndex20(uint256 _index, bool _isExpired, address _tokenPoolAddr) onlyOperator public{
        divide20PlanArray[_index].isExpired = _isExpired;
        if(_tokenPoolAddr != address(0)){
            divide20PlanArray[_index].tokenPoolAddr = _tokenPoolAddr;
        }
    }

    function setByTrcToken(uint256 _tokenId, bool _isExpired, address _tokenPoolAddr) onlyOperator public{
        for(uint256 i = 0 ; i < divide10PlanArray.length; i++){
           if(divide10PlanArray[i].trc10Id == _tokenId){
               divide10PlanArray[i].isExpired = _isExpired;
               if(_tokenPoolAddr != address(0)){
                   divide10PlanArray[i].tokenPoolAddr = _tokenPoolAddr;
               }
               break;
           }
        }
    }

    function setByTokenAddr(address _tokenAddr, bool _isExpired, address _tokenPoolAddr) onlyOperator public{
        for(uint256 i = 0 ; i < divide20PlanArray.length; i++){
            if(divide20PlanArray[i].trc20Addr == _tokenAddr){
                divide20PlanArray[i].isExpired = _isExpired;
                if(_tokenPoolAddr != address(0)){
                    divide20PlanArray[i].tokenPoolAddr = _tokenPoolAddr;
                }
                break;
            }
        }
    }

    function getDividePlanLength10() view public returns(uint256 planLength){
        planLength = divide10PlanArray.length;
    }

    function getDividePlanLength20() view public returns(uint256 planLength){
        planLength = divide20PlanArray.length;
    }

    function getDividePlan10(uint256 _index) view public returns(bool _isExpired, uint256 _trc10Id, uint256 _totalProfit, bool _active, address _tokenPoolAddr){
        require(_index < divide10PlanArray.length);
        _isExpired = divide10PlanArray[_index].isExpired;
        _trc10Id = divide10PlanArray[_index].trc10Id;
        _totalProfit = divide10PlanArray[_index].totalProfit;
        _active = divide10PlanArray[_index].active;
        _tokenPoolAddr = divide10PlanArray[_index].tokenPoolAddr;
    }

    function getDividePlan20(uint256 _index) view public returns(bool _isExpired, address _trc20Addr, uint256 _totalProfit, bool _active, address _tokenPoolAddr){
        require(_index < divide20PlanArray.length);
        _isExpired = divide20PlanArray[_index].isExpired;
        _trc20Addr = divide20PlanArray[_index].trc20Addr;
        _totalProfit = divide20PlanArray[_index].totalProfit;
        _active = divide20PlanArray[_index].active;
        _tokenPoolAddr = divide20PlanArray[_index].tokenPoolAddr;
    }

    function getDivideBalance(address _addr) view public returns(uint256 _balance, uint256[] memory _tokenId, uint256[] memory _balance10,address[] memory _tokenAddr, uint256[] memory _balance20){
        _balance = trxBalance[_addr];
        _tokenId = new uint256[](divide10PlanArray.length);
        _balance10 = new uint256[](divide10PlanArray.length);
        for(uint256 i = 0 ; i < divide10PlanArray.length; i++){
            _tokenId[i] = (divide10PlanArray[i].trc10Id);
            _balance10[i] = (divide10PlanArray[i].tokenBalance[_addr]);
        }
        _tokenAddr = new address[](divide20PlanArray.length);
        _balance20 = new uint256[](divide20PlanArray.length);
        for(uint256 j = 0 ; j < divide20PlanArray.length; j++){
            _tokenAddr[j] = (divide20PlanArray[j].trc20Addr);
            _balance20[j] = (divide20PlanArray[j].tokenBalance[_addr]);
        }
    }

    function getWithdrawalBalance(address _addr) view public returns(uint256 _balance, uint256[] memory _tokenId, uint256[] memory _balance10,address[] memory _tokenAddr, uint256[] memory _balance20){
        _balance = alreadyWithdrawal[_addr];
        _tokenId = new uint256[](divide10PlanArray.length);
        _balance10 = new uint256[](divide10PlanArray.length);
        for(uint256 i = 0 ; i < divide10PlanArray.length; i++){
            _tokenId[i] = (divide10PlanArray[i].trc10Id);
            _balance10[i] = (divide10PlanArray[i].alreadyWithdrawal[_addr]);
        }
        _tokenAddr = new address[](divide20PlanArray.length);
        _balance20 = new uint256[](divide20PlanArray.length);
        for(uint256 j = 0 ; j < divide20PlanArray.length; j++){
            _tokenAddr[j] = (divide20PlanArray[j].trc20Addr);
            _balance20[j] = (divide20PlanArray[j].alreadyWithdrawal[_addr]);
        }
    }

    function getWithdrawalBalanceTrx(address _addr) view public returns(uint256 _balance){
        _balance = alreadyWithdrawal[_addr];
    }

    function getDivideBalanceTrx(address _addr) view public returns(uint256 _balance){
        _balance = trxBalance[_addr];
    }

    function getDivideBalance10(address _addr) view public returns(uint256[] memory _tokenId, uint256[] memory _balance){
        _tokenId = new uint256[](divide10PlanArray.length);
        _balance = new uint256[](divide10PlanArray.length);
        for(uint256 i = 0 ; i < divide10PlanArray.length; i++){
            _tokenId[i] = (divide10PlanArray[i].trc10Id);
            _balance[i] = (divide10PlanArray[i].tokenBalance[_addr]);
        }
    }

    function getWithdrawalBalance10(address _addr) view public returns(uint256[] memory _tokenId, uint256[] memory _balance){
        _tokenId = new uint256[](divide10PlanArray.length);
        _balance = new uint256[](divide10PlanArray.length);
        for(uint256 i = 0 ; i < divide10PlanArray.length; i++){
            _tokenId[i] = (divide10PlanArray[i].trc10Id);
            _balance[i] = (divide10PlanArray[i].alreadyWithdrawal[_addr]);
        }
    }

    function getDivideBalance20(address _addr) view public returns(address[] memory _tokenAddr, uint256[] memory _balance){
        _tokenAddr = new address[](divide20PlanArray.length);
        _balance = new uint256[](divide20PlanArray.length);
        for(uint256 i = 0 ; i < divide20PlanArray.length; i++){
            _tokenAddr[i] = (divide20PlanArray[i].trc20Addr);
            _balance[i] = (divide20PlanArray[i].tokenBalance[_addr]);
        }
    }

    function getWithdrawalBalance20(address _addr) view public returns(address[] memory _tokenAddr, uint256[] memory _balance){
        _tokenAddr = new address[](divide20PlanArray.length);
        _balance = new uint256[](divide20PlanArray.length);
        for(uint256 i = 0 ; i < divide20PlanArray.length; i++){
            _tokenAddr[i] = (divide20PlanArray[i].trc20Addr);
            _balance[i] = (divide20PlanArray[i].alreadyWithdrawal[_addr]);
        }
    }

    function addPlan10(uint256 _trc10Id, address _tokenPoolAddr) onlyOperator public{
        divide10PlanArray.push(Objects.Divide10Plan({isExpired : false, trc10Id : _trc10Id, totalProfit : 0 , active : true, tokenPoolAddr : _tokenPoolAddr, divideUnit : 0}));
    }

    function addPlan20(address _trc20Addr, address _tokenPoolAddr) onlyOperator public{
        divide20PlanArray.push(Objects.Divide20Plan({isExpired : false, trc20Addr : _trc20Addr, totalProfit : 0, active : true, tokenPoolAddr : _tokenPoolAddr, divideUnit : 0}));
    }

    function withdrawalAll() public{
        uint256 trxValue = trxBalance[msg.sender];
        if(trxValue > 0){
            trxBalance[msg.sender] = 0;
            require(msg.sender.send(trxValue));
            alreadyWithdrawal[msg.sender] = alreadyWithdrawal[msg.sender].add(trxValue);
            emit WithdrawalAll(msg.sender, trxValue, 0, address(0), 0);
        }
        for(uint256 i = 0 ; i < divide10PlanArray.length; i++){
            uint256 trc10Value = divide10PlanArray[i].tokenBalance[msg.sender];
            if(trc10Value > 0){
                divide10PlanArray[i].tokenBalance[msg.sender] = 0;
                divide10PlanArray[i].alreadyWithdrawal[msg.sender] = divide10PlanArray[i].alreadyWithdrawal[msg.sender].add(trc10Value);
                msg.sender.transferToken(trc10Value, divide10PlanArray[i].trc10Id);
                emit WithdrawalAll(msg.sender, 0, divide10PlanArray[i].trc10Id, address(0), trc10Value);
            }
        }
        for(uint256 j = 0 ; j < divide20PlanArray.length; j++){
            uint256 trc20Value = divide20PlanArray[j].tokenBalance[msg.sender];
            if(trc20Value > 0){
                SimpleToken t = SimpleToken(divide20PlanArray[j].trc20Addr);
                divide20PlanArray[j].tokenBalance[msg.sender] = 0;
                divide20PlanArray[j].alreadyWithdrawal[msg.sender] = divide20PlanArray[j].alreadyWithdrawal[msg.sender].add(trc20Value);
                require(t.transfer(msg.sender, trc20Value));
                emit WithdrawalAll(msg.sender, 0, 0, divide20PlanArray[j].trc20Addr, trc20Value);
            }
        }
    }

    //webpage getInfo
    function getCurrentDivideTrxInfo() view public returns(uint256 _divideNum, uint256 _maxIndex, uint256 _currentIndex,
        uint256 _totalStake, uint256 _totalProfit, bool _active){
        _divideNum = divideNum;
        if(paused){
            _maxIndex = maxIndex;
            _currentIndex = currentIndex;
            _totalProfit = totalProfit;
            _totalStake = totalStake;
            _active = active;
        }else{
            SimpleStake s = SimpleStake(stakeAddr);
            SimplePool p = SimplePool(poolAddr);
            (_maxIndex, _totalStake) = s.getStakeInfo();
            _currentIndex = 0;
            (_totalProfit,_active) = p.getCurrentProfit();
        }
    }

    //webpage getInfo
    function getCurrentDivide10Info() view public returns(uint256[] memory trc10Array, uint256[] memory trc10Profit, bool[] activeArray){
        uint256 realLength10 = 0;
        for(uint256 m = 0 ; m < divide10PlanArray.length; m++){
            if(!divide10PlanArray[m].isExpired){
                realLength10++;
            }
        }
        trc10Array = new uint256[](realLength10);
        trc10Profit = new uint256[](realLength10);
        activeArray = new bool[](realLength10);
        if(paused){
            for(uint256 i = 0 ; i < divide10PlanArray.length; i++){
                if(!divide10PlanArray[i].isExpired){
                    realLength10--;
                    trc10Array[realLength10] = (divide10PlanArray[i].trc10Id);
                    trc10Profit[realLength10] = (divide10PlanArray[i].totalProfit);
                    activeArray[realLength10] = (divide10PlanArray[i].active);
                }
            }
        }else{
            bool tokenActive;
            uint256 tokenTotalProfit;
            for(uint256 k = 0 ; k < divide10PlanArray.length; k++){
                if(!divide10PlanArray[k].isExpired){
                    SimplePool p10 = SimplePool(divide10PlanArray[k].tokenPoolAddr);
                    (tokenTotalProfit,tokenActive) = p10.getCurrentProfit();
                    realLength10--;
                    trc10Array[realLength10] = (divide10PlanArray[k].trc10Id);
                    trc10Profit[realLength10] = (tokenTotalProfit);
                    activeArray[realLength10] = (tokenActive);
                }
            }
        }
    }

    function getCurrentDivide20Info() view public returns(address[] memory trc20Array,uint256[] memory trc20Profit, bool[] activeArray){
        uint256 realLength20 = 0;
        for(uint256 n = 0 ; n < divide20PlanArray.length; n++){
            if(!divide20PlanArray[n].isExpired){
                realLength20++;
            }
        }
        trc20Array = new address[](realLength20);
        trc20Profit = new uint256[](realLength20);
        activeArray = new bool[](realLength20);
        if(paused){
            for(uint256 j = 0 ; j < divide20PlanArray.length; j++){
                if(!divide20PlanArray[j].isExpired){
                    realLength20--;
                    trc20Array[realLength20] = (divide20PlanArray[j].trc20Addr);
                    trc20Profit[realLength20] = (divide20PlanArray[j].totalProfit);
                    activeArray[realLength20] = (divide20PlanArray[j].active);
                }
            }
        }else{
            bool tokenActive;
            uint256 tokenTotalProfit;
            for(uint256 q = 0 ; q < divide20PlanArray.length; q++){
                if(!divide20PlanArray[q].isExpired){
                    SimplePool p20 = SimplePool(divide20PlanArray[q].tokenPoolAddr);
                    (tokenTotalProfit,tokenActive) = p20.getCurrentProfit();
                    realLength20++;
                    trc20Array[realLength20] = (divide20PlanArray[q].trc20Addr);
                    trc20Profit[realLength20] = (tokenTotalProfit);
                    activeArray[realLength20] = (tokenActive);
                }
            }
        }
    }

    function setPoolAddr(address addr) onlyOperator public{
        poolAddr = addr;
    }

    function setStakeAddr(address addr) onlyOperator public{
        stakeAddr = addr;
    }


    function setConvertUnit(uint256 unit) onlyOperator public{
        convertUnit = unit;
    }

    function createDivide() onlyOperator whenNoPaused public returns(bool){
        divideNum++;
        SimpleStake s = SimpleStake(stakeAddr);
        (maxIndex, totalStake) = s.getStakeInfo();
        if(totalStake == 0){
            return paused;
        }
        if(poolAddr != address(0)){
            SimplePool p = SimplePool(poolAddr);
            (totalProfit, active) = p.withdrawalProfit();
            if(active){
                divideUnit = totalProfit.mul(convertUnit).div(totalStake);
            }else{
                divideUnit = 0;
            }
        }else{
            active = false;
            totalProfit = 0;
            divideUnit = 0;
        }
        bool isHasProfit10 = false;
        bool isHasProfit20 = false;
        for(uint256 k = 0 ; k < divide10PlanArray.length; k++){
            if(!divide10PlanArray[k].isExpired){
                SimplePool p10 = SimplePool(divide10PlanArray[k].tokenPoolAddr);
                (divide10PlanArray[k].totalProfit, divide10PlanArray[k].active) = p10.withdrawalProfit();
                if(divide10PlanArray[k].active){
                    isHasProfit10 = true;
                    divide10PlanArray[k].divideUnit = divide10PlanArray[k].totalProfit.mul(convertUnit).div(totalStake);
                }else{
                    divide10PlanArray[k].divideUnit = 0;
                }
            }
        }
        for(uint256 q = 0 ; q < divide20PlanArray.length; q++){
            if(!divide20PlanArray[q].isExpired){
                SimplePool p20 = SimplePool(divide20PlanArray[q].tokenPoolAddr);
                (divide20PlanArray[q].totalProfit, divide20PlanArray[q].active) = p20.withdrawalProfit();
                if(divide20PlanArray[q].active){
                    isHasProfit20 = true;
                    divide20PlanArray[q].divideUnit = divide20PlanArray[q].totalProfit.mul(convertUnit).div(totalStake);
                }else{
                    divide20PlanArray[q].divideUnit = 0;
                }
            }
        }
        currentIndex = 0;
        if(active || isHasProfit10 || isHasProfit20){
            s.doPause();
            paused = true;
        }
        return paused;
    }

    function doNextPay() onlyOperator whenPaused public returns(bool isSuccess, uint256 _currentIndex){
        currentIndex++;
        isSuccess = true;
        SimpleStake s = SimpleStake(stakeAddr);
        if(currentIndex >= maxIndex){
            paused = false;
            s.doUnPause();
            emit DivideComplete(divideNum,maxIndex, totalStake, totalProfit);
        }else{
            address currentAddr;
            uint256 stakeValue;
            (currentAddr, stakeValue) = s.getTokenStakeByIndex(currentIndex);
            if(active){
                uint256 divideValue = getDivideValue(divideUnit, stakeValue);
                trxBalance[currentAddr] = trxBalance[currentAddr].add(divideValue);
                emit DivideStep(divideNum, maxIndex, currentIndex, currentAddr,
                divideValue, stakeValue, totalStake, totalProfit);
            }
            for(uint256 k = 0 ; k < divide10PlanArray.length; k++){
                if(!divide10PlanArray[k].isExpired && divide10PlanArray[k].active){
                    divideValue = getDivideValue(divide10PlanArray[k].divideUnit, stakeValue);
                    divide10PlanArray[k].tokenBalance[currentAddr] = divide10PlanArray[k].tokenBalance[currentAddr].add(divideValue);
                    emit DivideStep10(divideNum, maxIndex, currentIndex, currentAddr, divide10PlanArray[k].trc10Id,
                        divideValue, stakeValue, totalStake, divide10PlanArray[k].totalProfit);
                }
            }
            for(uint256 q = 0 ; q < divide20PlanArray.length; q++){
                if(!divide20PlanArray[q].isExpired && divide20PlanArray[q].active){
                    divideValue = getDivideValue(divide20PlanArray[q].divideUnit, stakeValue);
                    divide20PlanArray[q].tokenBalance[currentAddr] = divide20PlanArray[q].tokenBalance[currentAddr].add(divideValue);
                    emit DivideStep20(divideNum, maxIndex, currentIndex, currentAddr, divide20PlanArray[q].trc20Addr,
                        divideValue, stakeValue, totalStake, divide20PlanArray[q].totalProfit);
                }
            }
        }
        _currentIndex = currentIndex;
    }

    function doIndexPay(uint256 _index) onlyOperator whenPaused public returns(bool isSuccess){
        require(_index < maxIndex,"index out of range");
        isSuccess = true;
        SimpleStake s = SimpleStake(stakeAddr);
        address currentAddr;
        uint256 stakeValue;
        (currentAddr, stakeValue) = s.getTokenStakeByIndex(_index);
        if(active){
            uint256 divideValue = getDivideValue(divideUnit, stakeValue);
            trxBalance[currentAddr] = trxBalance[currentAddr].add(divideValue);
            emit DivideStep(divideNum, maxIndex, currentIndex, currentAddr,
            divideValue, stakeValue, totalStake, totalProfit);
        }
        for(uint256 k = 0 ; k < divide10PlanArray.length; k++){
            if(!divide10PlanArray[k].isExpired && divide10PlanArray[k].active){
                divideValue = getDivideValue(divide10PlanArray[k].divideUnit, stakeValue);
                divide10PlanArray[k].tokenBalance[currentAddr] = divide10PlanArray[k].tokenBalance[currentAddr].add(divideValue);
                emit DivideStep10(divideNum, maxIndex, currentIndex, currentAddr, divide10PlanArray[k].trc10Id,
                    divideValue, stakeValue, totalStake, divide10PlanArray[k].totalProfit);
            }
        }
        for(uint256 q = 0 ; q < divide20PlanArray.length; q++){
            if(!divide20PlanArray[q].isExpired && divide20PlanArray[q].active){
                divideValue = getDivideValue(divide20PlanArray[q].divideUnit, stakeValue);
                divide20PlanArray[q].tokenBalance[currentAddr] = divide20PlanArray[q].tokenBalance[currentAddr].add(divideValue);
                emit DivideStep20(divideNum, maxIndex, currentIndex, currentAddr, divide20PlanArray[q].trc20Addr,
                    divideValue, stakeValue, totalStake, divide20PlanArray[q].totalProfit);
            }
        }
    }

    function getDivideValue(uint256 _divideUnit, uint256 _divideStake) view private returns(uint256){
        if(_divideStake == 0) return 0;
        return _divideStake.mul(_divideUnit).div(convertUnit);
    }


    function () public payable{

    }
    constructor() public {

    }
}