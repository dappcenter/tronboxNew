pragma solidity >=0.4.22 <0.6.0;

import "./WRPausable.sol";
library Objects {
    struct Record {
        string name;
        string value;
        string unit;
        string remark;
        uint256 status;//0 待挑战， 1 已挑战
        uint256 pre;
        uint256 later;
        uint256[] certificateArray;
        uint256 certValidCount;
    }
}
contract WRecord2  is WRPausable{
    Objects.Record[] public recordArray;
    event NewRecord(string indexed _name, string indexed _value, uint256 _recordId, string _unit, string _remark, uint256 _pre, uint256 _later);
    event BindCertificate(uint256 _recordId, uint256 _certId);
    function getRecordLength() view public returns(uint256 _len){
        _len = recordArray.length - 1;
    }

    function getNowRecord(uint256 _index) view public returns(uint256 _recordId, string memory _name, string memory _value, string memory _unit, string memory _remark, uint256 _status, uint256 _pre, uint256 _later){
        _recordId = _index;
        _name = recordArray[_index].name;
        _value = recordArray[_index].value;
        _unit = recordArray[_index].unit;
        _remark = recordArray[_index].remark;
        _status = recordArray[_index].status;
        _pre = recordArray[_index].pre;
        _later = recordArray[_index].later;
    }

    function getBindCertificate(uint256 _index) view public returns(uint256[] memory certIds, uint256 _certValidCount){
        _certValidCount = recordArray[_index].certValidCount;
        certIds = new uint256[](recordArray[_index].certificateArray.length);
        for(uint256 i = 0 ; i < certIds.length; i++){
            certIds[i] = (recordArray[_index].certificateArray[i]);
        }
    }

    function isRecordLast(uint256 _index) view public returns(bool){
        if(recordArray[_index].certValidCount == 0){
            return false;
        }
        Objects.Record memory temp = recordArray[_index];
        while(temp.later != 0 && recordArray[temp.later].certValidCount == 0){
            temp = recordArray[temp.later];
        }
        return temp.later == 0;
    }

    function isRecordFirst(uint256 _index) view public returns(bool){
        if(recordArray[_index].certValidCount == 0){
            return false;
        }
        Objects.Record memory temp = recordArray[_index];
        while(temp.pre != 0 && recordArray[temp.pre].certValidCount == 0){
            temp = recordArray[temp.pre];
        }
        return temp.pre == 0;
    }

    function getPreRecord(uint256 _index) view public returns(uint256 _recordId, string memory _name, string memory _value, string memory _unit, string memory _remark, uint256 _status, uint256 _pre, uint256 _later){
        _index = recordArray[_index].pre;
        _recordId = _index;
        _name = recordArray[_index].name;
        _value = recordArray[_index].value;
        _unit = recordArray[_index].unit;
        _remark = recordArray[_index].remark;
        _status = recordArray[_index].status;
        _pre = recordArray[_index].pre;
        _later = recordArray[_index].later;
    }

    function getLaterRecord(uint256 _index) view public returns(uint256 _recordId, string memory _name, string memory _value, string memory _unit, string memory _remark, uint256 _status, uint256 _pre, uint256 _later){
        _index = recordArray[_index].later;
        _recordId = _index;
        _name = recordArray[_index].name;
        _value = recordArray[_index].value;
        _unit = recordArray[_index].unit;
        _remark = recordArray[_index].remark;
        _status = recordArray[_index].status;
        _pre = recordArray[_index].pre;
        _later = recordArray[_index].later;
    }

    function bindCertificate(uint256 _recordId, uint256 _certId) onlyOperator public{
        _bindCertificate(_recordId, _certId);
    }

    function bindCertificateArray(uint256 _recordId, uint256[] memory _certIds) onlyOperator public{
        for(uint256 i = 0; i < _certIds.length; i++){
            _bindCertificate(_recordId, _certIds[i]);
        }
    }

    function _bindCertificate(uint256 _recordId, uint256 _certId) private{
        require(_recordId < recordArray.length,"recordId is invalid");
        require(_recordId > 0 && _certId >0, "id is invalid, must bigger than zero");
        for(uint256 i = 0; i < recordArray[_recordId].certificateArray.length; i++){
            if(recordArray[_recordId].certificateArray[i] == _certId){
                return;
            }
        }
        if(recordArray[_recordId].status == 0){
            recordArray[_recordId].status = 1;
        }
        recordArray[_recordId].certificateArray.push(_certId);
        emit BindCertificate(_recordId, _certId);
    }

    function certificateIncre(uint256 _recordId) onlyOperator public{
        recordArray[_recordId].certValidCount++;
    }

    function certificateDecre(uint256 _recordId) onlyOperator public{
        require(recordArray[_recordId].certValidCount > 0);
        recordArray[_recordId].certValidCount--;
    }

    function updateRecord(uint256 _index, string memory _name, string memory _value, string memory _unit, string memory _remark, uint256 _status, uint256 _pre, uint256 _later) onlyOperator public{
        recordArray[_index].name = _name;
        recordArray[_index].value = _value;
        recordArray[_index].unit = _unit;
        recordArray[_index].remark = _remark;
        recordArray[_index].status = _status;
        recordArray[_index].pre = _pre;
        recordArray[_index].later = _later;
    }

    function updateBaseInfo(uint256 _index, string memory _name, string memory _value, string memory _unit, string memory _remark) onlyOperator public{
        recordArray[_index].name = _name;
        recordArray[_index].value = _value;
        recordArray[_index].unit = _unit;
        recordArray[_index].remark = _remark;
    }

    function undateCertificateArray(uint256 _index, uint256[] memory _certificateArray) onlyOperator public{
        recordArray[_index].certificateArray = _certificateArray;
    }

    function updateStatus(uint256 _index, uint256 _status) onlyOperator public{
        recordArray[_index].status = _status;
    }

    function updatePreLater(uint256 _index, uint256 _pre, uint256 _later) onlyOperator public{
        recordArray[_index].pre = _pre;
        recordArray[_index].later = _later;
    }

    function updatePre(uint256 _index, uint256 _pre) onlyOperator public{
        recordArray[_index].pre = _pre;
    }

    function updateLater(uint256 _index, uint256 _later) onlyOperator public{
        recordArray[_index].later = _later;
    }

    function newRecord(string memory _name, string memory _value, string memory _unit, string memory _remark, uint256 _pre, uint256 _later) onlyOperator public returns(uint256 _recordId){
        _recordId = recordArray.push(Objects.Record({name : _name, value : _value, unit : _unit, remark : _remark, status : 0, pre : _pre, later : _later, certificateArray: new uint256[](0), certValidCount : 0})) - 1;
        if(_pre != 0){
            recordArray[_pre].later = _recordId;
        }
        emit NewRecord(_name, _value, _recordId, _unit, _remark, _pre, _later);
    }

    function () payable external{
    }

    constructor () public {
        recordArray.push(Objects.Record({name : "", value : "", unit : "", remark : "", status : 0, pre : 0, later : 0, certificateArray: new uint256[](0), certValidCount : 0}));
    }
}
