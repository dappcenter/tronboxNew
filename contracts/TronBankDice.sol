pragma solidity ^0.4.0;

import "./Pausable.sol";
import "./SafeMath.sol";
contract SimpleReferral{
    function getReferral(address target) view public returns(address);
    function getAddrByReferralCode(string code) view public returns(address);
    function setReferral(address target, address mentor) public;
    function addReferralBonus(address _addr, uint256 _bonus) public returns(uint256);
}

contract SimplePool{
    function transferTrx(address to, uint256 value) public;
    function transferTrx2(address to1, uint256 value1, address to2, uint256 value2) public;
}

contract TronBankDice is Pausable {
    using SafeMath for uint256;
    uint256[] public winRateArray = new uint256[](101);
    mapping(address => bool) public bettorMap;
    address public poolAddr;
    address public referralAddr;
    uint256 public minBetValue = 10e6;
    uint256 public maxBetValue = 100000e6;
    uint256 public underMin = 2;
    uint256 public underMax = 95;
    uint256 public overMin = 4;
    uint256 public overMax = 98;
    uint256 public poolRate = 10e2;
    uint256 public cutPointRate = 960e3;

    event Dice(address indexed bettor, uint256 betNum, uint256 direction, string indexed code);
    event DiceResult(uint256 betTxId, address indexed bettor, address indexed mentor,
        uint256 bonus, uint256 betNum, uint256 direction, uint256 betValue, uint256 rollNum, uint256 winValue);

    function withdrawal(uint256 value) onlyOperator public returns(bool){
        return msg.sender.send(value);
    }

    function setPoolRate(uint256 value) onlyOperator public{
        poolRate = value;
    }

    function setWinRate(uint256 _index, uint256 value) onlyOperator public{
        winRateArray[_index] = value;
    }

    function setCutPointRate(uint256 value) onlyOperator public{
        cutPointRate = value;
    }

    function setPoolAddr(address addr) onlyOperator public{
        poolAddr = addr;
    }

    function setReferralAddr(address addr) onlyOperator public{
        referralAddr = addr;
    }

    function setMinBetValue(uint256 value) onlyOperator public{
        minBetValue = value;
    }

    function setUnderMin(uint256 value) onlyOperator public{
        underMin = value;
    }

    function setUnderMax(uint256 value) onlyOperator public{
        underMax = value;
    }

    function setOverMin(uint256 value) onlyOperator public{
        overMin = value;
    }

    function setOverMax(uint256 value) onlyOperator public{
        overMax = value;
    }

    function setMaxBetValue(uint256 value) onlyOperator public{
        maxBetValue = value;
    }

    function callBack(uint256 betTxId, address bettor, address mentor,
        uint256 bonus, uint256 betNum, uint256 direction,
        uint256 betValue, uint256 rollNum, uint256 winValue) onlyOperator public returns(bool){
        if(winValue > 0){
            SimplePool p = SimplePool(poolAddr);
            if(mentor == address(0)){
                p.transferTrx(bettor, winValue);
            }else{
                p.transferTrx2(bettor, winValue, mentor, bonus);
                SimpleReferral r = SimpleReferral(referralAddr);
                r.addReferralBonus(mentor, bonus);
            }
        }
        emit DiceResult(betTxId, bettor, mentor,
            bonus, betNum, direction, betValue, rollNum, winValue);
    }

    function callBack2(uint256 betTxId, address bettor
    ,uint256 betNum, uint256 direction,
        uint256 betValue, uint256 rollNum, uint256 winValue) onlyOperator public returns(bool){
        if(winValue > 0){
            SimplePool p = SimplePool(poolAddr);
            p.transferTrx(bettor, winValue);
        }
        emit DiceResult(betTxId, bettor, address(0),
            0, betNum, direction, betValue, rollNum, winValue);
    }

    function luckyDice(uint256 betNum, uint256 direction) whenNoPaused payable public returns(bool){
        require(isHuman(msg.sender),"code address is not allow");
        isValid(betNum, direction,msg.value);
        require(poolAddr.call.value(msg.value)(),"transfer to pool failed");
        bettorMap[msg.sender] = true;
        emit Dice(msg.sender, betNum, direction, "");
        return true;
    }

    function referralLuckyDice(uint256 betNum, uint256 direction, string code) whenNoPaused payable public returns(bool){
        require(isHuman(msg.sender),"code address is not allow");
        isValid(betNum, direction,msg.value);
        SimpleReferral r = SimpleReferral(referralAddr);
        if(r.getReferral(msg.sender) == address(0)){
            address referral = r.getAddrByReferralCode(code);
            if(referral != address(0) && referral != msg.sender){
                r.setReferral(msg.sender, referral);
            }
        }
        require(poolAddr.call.value(msg.value)(),"transfer to pool failed");
        bettorMap[msg.sender] = true;
        emit Dice(msg.sender, betNum, direction, code);
        return true;
    }

    function isHuman(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size == 0;
    }

    function initWinRate() onlyOperator public{
        for(uint i = 1; i <= 100; i++){
            winRateArray[i] = cutPointRate.div(i);
        }
    }

    function isValid(uint256 betNum, uint256 direction, uint256 value) view private{
        require(direction == 0 || direction == 1,"direction invalid");
        if(direction == 0){//roll under
            require(betNum >= underMin && betNum <= underMax,"betNum invalid");
        }else{//roll over
            require(betNum >= overMin && betNum <= overMax,"betNum invalid");
        }
        require(value >= minBetValue && value <= maxBetValue,"betValue invalid");
        require(poolAddr.balance.mul(poolRate) > value.mul(winRateArray[betNum]),"win trx is bigger than pool rate");
    }

    function () public payable{

    }

    constructor() public {
        initWinRate();
    }

}
