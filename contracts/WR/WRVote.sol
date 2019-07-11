pragma solidity >=0.4.22 <0.6.0;

import "./WRPausable.sol";
contract SimpleRecord{
    function getNowRecord(uint256 _index) view external returns(uint256 _recordId, string memory _name, string memory _value, string memory _unit, string memory _remark, uint256 _status, uint256 _pre, uint256 _later);
    function newRecord(string calldata _name, string calldata _value, string calldata _unit, string calldata _remark, uint256 _pre, uint256 _later) external returns(uint256 _recordId);
}
contract SimpleAward{
function getCertificateInfo(uint256 _tokenId) view external returns(bool _isRecordHolder, string memory _challengeName, uint256 _recordId, uint256 _challengeTime, string memory _challengeLocation, string memory _videoUri, uint256 _checkTime, string memory _remark, uint256 _status);
function checkStatus(uint256 _certId, bool _isAgree) external;
function award(address _owner, string calldata _challengeName, uint256 _recordId, uint256 _challengeTime, string calldata _challengeLocation, string calldata _videoUri, string calldata _remark) external returns(uint256 _certId);

}
contract WRVote is WRPausable{
address public recordAddr;
address public certAddr;
mapping(address => uint256) public lastCreateRecord;
mapping(address => uint256) public lastCreateCert;

function newRecord(string memory _name, string memory _value, string memory _unit, string memory _remark, uint256 _pre, uint256 _later) onlyOperator public returns(uint256 _recordId){
_recordId = SimpleRecord(recordAddr).newRecord(_name, _value, _unit, _remark, _pre, _later);
lastCreateRecord[msg.sender] = _recordId;
}

function setRecordAddr(address _addr) onlyCLevel public{
recordAddr = _addr;
}

function setCertAddr(address _addr) onlyCLevel public{
certAddr = _addr;
}

function awardAndCheck(address _owner, string memory _challengeName, uint256 _challengeTime, string memory _challengeLocation, string memory _videoUri, string memory _remark) onlyOperator public returns(uint256 _certId){
_certId = award(_owner, _challengeName, _challengeTime, _challengeLocation, _videoUri, _remark);
checkStatus2(_certId, true);
}

function award(address _owner, string memory _challengeName, uint256 _challengeTime, string memory _challengeLocation, string memory _videoUri, string memory _remark) onlyOperator public returns(uint256 _certId){
require(lastCreateRecord[msg.sender] != 0);
_certId = SimpleAward(certAddr).award(_owner, _challengeName, lastCreateRecord[msg.sender], _challengeTime, _challengeLocation, _videoUri, _remark);
lastCreateCert[msg.sender] = _certId;
}

function checkStatus(bool _isAgree) onlyOperator public{
SimpleAward(certAddr).checkStatus(lastCreateCert[msg.sender], _isAgree);
}

function checkStatus2(uint256 _certId, bool _isAgree) onlyOperator public{
SimpleAward(certAddr).checkStatus(_certId, _isAgree);
}

function getNowRecord(uint256 _index) view public returns(uint256 _recordId, string memory _name, string memory _value, string memory _unit, string memory _remark, uint256 _status, uint256 _pre, uint256 _later){
(_recordId,_name,_value,_unit,_remark,_status, _pre, _later) = SimpleRecord(recordAddr).getNowRecord(_index);
}

function getCertificateInfo(uint256 _tokenId) view public returns(string memory _challengeName, uint256 _recordId, uint256 _challengeTime, string memory _challengeLocation, string memory _videoUri, uint256 _checkTime, string memory _remark, uint256 _status){
(,
_challengeName,
_recordId,
_challengeTime,
_challengeLocation,
_videoUri,
_checkTime,
_remark,
_status) = SimpleAward(certAddr).getCertificateInfo(_tokenId);
}

function () payable external{

}

constructor () public {
}
}
