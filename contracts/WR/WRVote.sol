pragma solidity >=0.4.22 <0.6.0;

import "./WRPausable.sol";
contract SimpleRecord{
    function getNowRecord(uint256 _index) view external returns(uint256 _recordId, string memory _name, string memory _remark, uint256 _status, uint256 _lastCertId, uint256 _certValidCount);
    function newRecord(string memory _name, string memory _remark) public returns(uint256 _recordId);
}
contract SimpleAward{
    function getCertificateBaseInfo(uint256 _tokenId) view external returns(bool _isRecordHolder, string memory _challengeName, uint256 _recordId, uint256 _ref, string memory _value, uint256 _challengeTime, string memory _challengeLocation, string memory _videoUri, uint256 _pre, uint256 _later, uint256 _status);
    function changeStatus(uint256 _certId, uint256 _status) external;
    function award(address _owner, string memory _value, string memory _challengeName, uint256 _recordId, uint256 _challengeTime, string memory _challengeLocation, string memory _videoUri, string memory _remark) public returns(uint256 _certId);
}
contract WRVote is WRPausable{
    address public recordAddr;
    address public certAddr;
    mapping(address => uint256) public lastCreateRecord;
    mapping(address => uint256) public lastCreateCert;

    function newRecord(string memory _name, string memory _remark) onlyOperator public returns(uint256 _recordId){
        _recordId = SimpleRecord(recordAddr).newRecord(_name, _remark);
        lastCreateRecord[msg.sender] = _recordId;
    }

    function setRecordAddr(address _addr) onlyCLevel public{
        recordAddr = _addr;
    }

    function setCertAddr(address _addr) onlyCLevel public{
        certAddr = _addr;
    }

    function awardAndCheck(address _owner, string memory _value, string memory _challengeName, uint256 _challengeTime, string memory _challengeLocation, string memory _videoUri, string memory _remark) onlyOperator public returns(uint256 _certId){
        _certId = award(_owner, _value, _challengeName, _challengeTime, _challengeLocation, _videoUri, _remark);
        changeStatus2(_certId, 1);
    }

    function award(address _owner, string memory _value, string memory _challengeName, uint256 _challengeTime, string memory _challengeLocation, string memory _videoUri, string memory _remark) onlyOperator public returns(uint256 _certId){
        require(lastCreateRecord[msg.sender] != 0);
        _certId = SimpleAward(certAddr).award(_owner, _value, _challengeName, lastCreateRecord[msg.sender], _challengeTime, _challengeLocation, _videoUri, _remark);
        lastCreateCert[msg.sender] = _certId;
    }

    function changeStatus(uint256 _status) onlyOperator public{
        SimpleAward(certAddr).changeStatus(lastCreateCert[msg.sender], _status);
    }

    function changeStatus2(uint256 _certId,uint256 _status) onlyOperator public{
        SimpleAward(certAddr).changeStatus(_certId, _status);
    }

    function getNowRecord(uint256 _index) view public returns(uint256 _recordId, string memory _name, string memory _remark, uint256 _status, uint256 _lastCertId, uint256 _certValidCount){
        (_recordId, _name, _remark, _status, _lastCertId, _certValidCount) = SimpleRecord(recordAddr).getNowRecord(_index);
    }

    function getCertificateBaseInfo(uint256 _tokenId) view public returns(string memory _challengeName, uint256 _recordId, uint256 _ref, string memory _value, string memory _videoUri, uint256 _pre, uint256 _later, uint256 _status){
        (,
        _challengeName,
        _recordId,
        _ref,
        _value,
        ,
        ,
        _videoUri,
        _pre,
        _later,
        _status) = SimpleAward(certAddr).getCertificateBaseInfo(_tokenId);
    }

    function () payable external{

    }

    constructor () public {
    }
}
