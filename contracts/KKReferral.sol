pragma solidity ^0.4.0;

import "./Pausable.sol";
import "./SafeMath.sol";
contract KKReferral is Pausable{
    struct AddressInfo {
        address addr;
        string referralCode;
        uint256 referralBonus;
        uint256 level1RefCount;
        uint256 level2RefCount;
        uint256 level3RefCount;
    }
    using SafeMath for uint256;
    mapping(address => address) referralMap;//target:mentor
    mapping(string => address) codeToAddrMap;
    mapping(address => uint256) addressToIndexMap;
    AddressInfo[] addressInfoArray;//easy to backup

    event CreateReferral(address indexed owner, string indexed code);
    event Referral(address indexed target, address indexed mentor);

    function getReferralBonus(address _addr) view public returns(uint256){
        return addressInfoArray[addressToIndexMap[_addr]].referralBonus;
    }

    function getReferralArray(address _first, uint256 _maxIndex) view onlyOperator public returns(address[] memory addressArray, uint256 realLength){
        addressArray = new address[](_maxIndex);
        for(uint256 i = 0; i < _maxIndex; i++){
            address next = referralMap[_first];
            if(next == address(0)){
                break;
            }
            addressArray[i] = next;
            _first = next;
            realLength++;
        }

    }

    function addReferralBonus(address _addr, uint256 _bonus) onlyOperator public returns(uint256){
        AddressInfo storage ai = addressInfoArray[addressToIndexMap[_addr]];
        ai.referralBonus = ai.referralBonus.add(_bonus);
        return ai.referralBonus;
    }

    function getReferral(address target) view public returns(address){
        return referralMap[target];
    }

    function getAddressInfoLength() view onlyOperator public returns(uint256){
        return addressInfoArray.length;
    }

    function getAddressInfoByIndex(uint256 _index) view onlyOperator public returns(address _addr, string _referralCode, uint256 _referralBonus, uint256 _level1RefCount, uint256 _level2RefCount, uint256 _level3RefCount){
        AddressInfo memory ai = addressInfoArray[_index];
        _addr = ai.addr;
        _referralCode = ai.referralCode;
        _referralBonus = ai.referralBonus;
        _level1RefCount = ai.level1RefCount;
        _level2RefCount = ai.level2RefCount;
        _level3RefCount = ai.level3RefCount;
    }

    function addAddressInfo(address _addr, string _referralCode, uint256 _referralBonus, uint256 _level1, uint256 _level2, uint256 _level3) onlyOwner public{
        uint256 _index = addressToIndexMap[_addr];
        if(_index == 0){
            addressToIndexMap[_addr] = addressInfoArray.push(AddressInfo({addr:_addr,referralCode:_referralCode, referralBonus : _referralBonus,level1RefCount:_level1,level2RefCount:_level2,level3RefCount:_level3})) - 1;
        }else{
            AddressInfo storage ai = addressInfoArray[_index];
            ai.addr = _addr;
            ai.referralCode = _referralCode;
            ai.referralBonus = _referralBonus;
            ai.level1RefCount = _level1;
            ai.level2RefCount = _level2;
            ai.level3RefCount = _level3;
        }
    }

    function addReferral(address target, address mentor) onlyOwner public{
        referralMap[target] = mentor;
        AddressInfo storage level1 = addressInfoArray[addressToIndexMap[mentor]];
        level1.level1RefCount = level1.level1RefCount.add(1);
        if(!(getReferral(level1.addr) == address(0))){
            AddressInfo storage level2 = addressInfoArray[addressToIndexMap[getReferral(level1.addr)]];
            level2.level2RefCount = level2.level2RefCount.add(1);
            if(!(getReferral(level2.addr) == address(0))){
                AddressInfo storage level3 = addressInfoArray[addressToIndexMap[getReferral(level2.addr)]];
                level3.level3RefCount = level3.level3RefCount.add(1);
            }
        }
    }

    function getAddressInfoByAddr(address addr) view public returns(address _addr, string _referralCode, uint256 _referralBonus, uint256 _level1RefCount, uint256 _level2RefCount, uint256 _level3RefCount){
        AddressInfo memory temp = addressInfoArray[addressToIndexMap[addr]];
        _addr = temp.addr;
        _referralCode = temp.referralCode;
        _referralBonus = temp.referralBonus;
        _level1RefCount = temp.level1RefCount;
        _level2RefCount = temp.level2RefCount;
        _level3RefCount = temp.level3RefCount;
    }

    function createReferralCode(string code) whenNoPaused public{
        require(addressToIndexMap[msg.sender] == 0,"already set referral code");
        bytes memory temp = bytes(code);
        require(temp.length >= 4 && temp.length <= 16,"code length is invalid");
        for (uint i = 0; i < temp.length; i ++) {
            require((temp[i] >= byte('a') && temp[i] <= byte('z')) || (temp[i] >= byte('A') && temp[i] <= byte('Z'))
                || (temp[i] >= byte('0') && temp[i] <= byte('9')),"code content is invalid");
        }
        require(codeToAddrMap[code] == address(0),"code is repeated");
        codeToAddrMap[code] = msg.sender;
        addressToIndexMap[msg.sender] = addressInfoArray.push(AddressInfo({addr:msg.sender,referralCode:code,referralBonus:0,level1RefCount:0,level2RefCount:0,level3RefCount:0})) - 1;
        emit CreateReferral(msg.sender, code);
    }

    function getReferralCodeByAddr(address mentor) view public returns(string){
        return addressInfoArray[addressToIndexMap[mentor]].referralCode;
    }

    function getAddrByReferralCode(string code) view public returns(address){
        return codeToAddrMap[code];
    }

    function setReferral(address target, address mentor) onlyOperator whenNoPaused public{
        require(getReferral(target) == address(0),"referral is already exits");
        referralMap[target] = mentor;
        AddressInfo storage level1 = addressInfoArray[addressToIndexMap[mentor]];
        level1.level1RefCount = level1.level1RefCount.add(1);
        if(!(getReferral(level1.addr) == address(0))){
            AddressInfo storage level2 = addressInfoArray[addressToIndexMap[getReferral(level1.addr)]];
            level2.level2RefCount = level2.level2RefCount.add(1);
            if(!(getReferral(level2.addr) == address(0))){
                AddressInfo storage level3 = addressInfoArray[addressToIndexMap[getReferral(level2.addr)]];
                level3.level3RefCount = level3.level3RefCount.add(1);
            }
        }
        emit Referral(target, mentor);
    }

    function () payable public{
        revert();
    }
    constructor () public {
        addressInfoArray.push(AddressInfo({addr:address(0),referralCode:"", referralBonus:0, level1RefCount:0,level2RefCount:0,level3RefCount:0}));
    }
}
