pragma solidity >=0.4.22 <0.6.0;

import "./WRPausable.sol";
library Objects {
    struct Record {
        string name;
        string remark;
        uint256 status;//0 不可挑战， 1 可以挑战
        uint256 lastCertId;
        uint256 certValidCount;
    }
}
contract WRecord3  is WRPausable{
    Objects.Record[] public recordArray;
    event NewRecord(string indexed _name, uint256 _recordId, string _remark);
    event BindCertificate(uint256 indexed _recordId, uint256 _oldCertId, uint256 _lastCertId, uint256 _certValidCount);
    event UnBindCertificate(uint256 indexed _recordId, uint256 _oldCertId, uint256 _lastCertId, uint256 _laterCertId, uint256 _certValidCount);
    event RecoveryCertificate(uint256 indexed _recordId, uint256 _oldCertId, uint256 _lastCertId, uint256 _laterCertId, uint256 _certValidCount);

    function getRecordLength() view public returns(uint256 _len){
        _len = recordArray.length - 1;
    }

    function getNowRecord(uint256 _index) view public returns(uint256 _recordId, string memory _name, string memory _remark, uint256 _status, uint256 _lastCertId, uint256 _certValidCount){
        _recordId = _index;
        _name = recordArray[_index].name;
        _remark = recordArray[_index].remark;
        _status = recordArray[_index].status;
        _lastCertId = recordArray[_index].lastCertId;
        _certValidCount = recordArray[_index].certValidCount;
    }

    function getLastBindCertificate(uint256 _index) view public returns(uint256 _lastCertId){
        _lastCertId = recordArray[_index].lastCertId;
    }

    function getCertValidCount(uint256 _index) view public returns(uint256 _certValidCount){
        _certValidCount = recordArray[_index].certValidCount;
    }

    function bindCertificate(uint256 _recordId, uint256 _certId) onlyOperator public returns(uint256 _preCertId){
        _preCertId =  _bindCertificate(_recordId, _certId);
    }

    function _bindCertificate(uint256 _recordId, uint256 _certId) private returns(uint256 _preCertId){
        require(_recordId < recordArray.length,"recordId is invalid");
        require(recordArray[_recordId].status == 1, "the record is not open to challenge!");
        _preCertId = recordArray[_recordId].lastCertId;
        recordArray[_recordId].lastCertId = _certId;
        recordArray[_recordId].certValidCount++;
        emit BindCertificate(_recordId, _preCertId, _certId, recordArray[_recordId].certValidCount);
    }

    function unBindCertificate(uint256 _recordId, uint256 _preCertId, uint256 _certId, uint256 _laterCertId) onlyOperator public{
        require(_recordId < recordArray.length,"recordId is invalid");
        require(recordArray[_recordId].certValidCount > 0, "nothing to unbind");
        if(_laterCertId == 0){
            require(recordArray[_recordId].lastCertId == _certId,"_preCertId is not match now lastCertId!");//TODO need require?
            recordArray[_recordId].lastCertId = _preCertId;
        }
        recordArray[_recordId].certValidCount--;
        emit UnBindCertificate(_recordId, _preCertId, _certId, _laterCertId, recordArray[_recordId].certValidCount);
    }

    function recoveryCertificate(uint256 _recordId, uint256 _preCertId, uint256 _certId, uint256 _laterCertId) onlyOperator public{
        require(_recordId < recordArray.length,"recordId is invalid");
        if(_laterCertId == 0){
            require(recordArray[_recordId].lastCertId == _preCertId,"_preCertId is not match now lastCertId!");//TODO need require
            recordArray[_recordId].lastCertId = _certId;
        }
        recordArray[_recordId].certValidCount++;
        emit RecoveryCertificate(_recordId, _preCertId, _certId, _laterCertId, recordArray[_recordId].certValidCount);
    }

    function updateBaseInfo(uint256 _index, string memory _name, string memory _remark) onlyOperator public{
        recordArray[_index].name = _name;
        recordArray[_index].remark = _remark;
    }

    function undateLastCertId(uint256 _index, uint256 _lastCertId) onlyOperator public{
        recordArray[_index].lastCertId = _lastCertId;
    }

    function updateStatus(uint256 _index, uint256 _status) onlyOperator public{
        recordArray[_index].status = _status;
    }

    function newRecord(string memory _name, string memory _remark) onlyOperator public returns(uint256 _recordId){
        _recordId = recordArray.push(Objects.Record({name : _name, remark : _remark, status : 1, lastCertId : 0, certValidCount: 0})) - 1;
        emit NewRecord(_name, _recordId, _remark);
    }

    function () payable external{
    }

    constructor () public {
        recordArray.push(Objects.Record({name : "", remark : "", status : 0, lastCertId: 0, certValidCount: 0}));
    }
}
