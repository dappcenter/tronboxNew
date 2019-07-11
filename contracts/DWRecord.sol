pragma solidity >=0.4.22 <0.6.0;

import "./DWPausable.sol";
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
    }
}
contract DWRecord  is DWPausable{
    Objects.Record[] public recordArray;

    function getRecordLength() view public returns(uint256 _len){
        _len = recordArray.length;
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

    function getBindCertificate(uint256 _index) view public returns(uint256[] memory certIds){
        certIds = new uint256[](recordArray[_index].certificateArray.length);
        for(uint256 i = 0 ; i < certIds.length; i++){
            certIds[i] = (recordArray[_index].certificateArray[i]);
        }
    }

    function isRecordLast(uint256 _index) view public returns(bool){
        return recordArray[_index].later == 0;
    }

    function isRecordFirst(uint256 _index) view public returns(bool){
        return recordArray[_index].pre == 0;
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
        recordArray[_recordId].certificateArray.push(_certId);
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

    function updateStatus(uint256 _index, uint256 _status) onlyOperator public{
        recordArray[_index].status = _status;
    }

    function updatePreLater(uint256 _index, uint256 _pre, uint256 _later) onlyOperator public{
        recordArray[_index].pre = _pre;
        recordArray[_index].later = _later;
    }

    function createRecord(string memory _name, string memory _value, string memory _unit, string memory _remark, uint256 _status, uint256 _pre, uint256 _later) onlyOperator public returns(uint256 _recordId){
        _recordId = recordArray.push(Objects.Record({name : _name, value : _value, unit : _unit, remark : _remark, status : _status, pre : _pre, later : _later, certificateArray: new uint256[](0)})) - 1;
        if(_pre != 0){
            recordArray[_pre].later = _recordId;
        }
    }

    function () payable external{
    }

    constructor () public {
        recordArray.push(Objects.Record({name : "", value : "", unit : "", remark : "", status : 0, pre : 0, later : 0, certificateArray: new uint256[](0)}));
    }
}
