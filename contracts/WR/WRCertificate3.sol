pragma solidity >=0.4.22 <0.6.0;

import "./WRPausable.sol";

contract  ERC721TokenReceiver {
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
}

contract SimpleRecord{
function recoveryCertificate(uint256 _recordId, uint256 _preCertId, uint256 _certId, uint256 _laterCertId) external;
function unBindCertificate(uint256 _recordId, uint256 _preCertId, uint256 _certId, uint256 _laterCertId) external;
function bindCertificate(uint256 _recordId, uint256 _certId) external returns(uint256 _preCertId);
}

contract ERC165{
function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}

contract ERC721Metadata {
function name() external view returns (string memory _name);
function symbol() external view returns (string memory _symbol);
function tokenURI(uint256 _tokenId) external view returns (string memory);
}

contract ERC721Enumerable{
function totalSupply() external view returns (uint256);
function tokenByIndex(uint256 _index) external view returns (uint256);
function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}

contract ERC721 is ERC165, ERC721Enumerable, ERC721Metadata{
// Events
event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

function balanceOf(address _owner) external view returns (uint256);
function ownerOf(uint256 _tokenId) external view returns (address);

function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) external payable;
function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
function transfer(address _to, uint256 _tokenId) external;

function approve(address _to, uint256 _tokenId) external;
function setApprovalForAll(address _operator, bool _approved) external;
function getApproved(uint256 _tokenId) external view returns (address);
function isApprovedForAll(address _owner, address _operator) external view returns (bool);

function tokensOfOwner(address _owner) external view returns (uint256[] memory);
}

contract WRCertificate3 is ERC721, WRPausable{
struct Certificate{
string challengeName;
uint256 recordId;
string value;
uint256 challengeTime;
string challengeLocation;
string videoUri;
uint256 checkTime;
uint256 pre;
uint256 later;
string remark;
uint256 status;// 0-待审核，1-审核通过，2-审核未通过，4-作废
}
event Award(address indexed _owner, string indexed _challengeName, uint256 _certId, uint256 _recordId, string _value, uint256 _challengeTime, string _challengeLocation, string _videoUri, uint256 _checkTime, uint256 _preCertId, string _remark, uint256 _status);
event CheckResult(uint256 indexed _certId,bool _isAgree);
event Burned(address indexed _owner, uint256 _tokenId, uint256 _preCertId, uint256 _laterCertId, uint256 _status);
event ReturnBack(address indexed _owner, uint256 _tokenId, uint256 _preCertId, uint256 _laterCertId, uint256 _status);
Certificate[] private certificates;
mapping(uint256 => address) private certIndexToOwner;
mapping(uint256 => address) private burnedCertIndexToOwner;
mapping(address => uint256) private ownerToTokenCount;
mapping(address => uint256) private ownerToBurnedTokenCount;
mapping(uint256 => address) private certIndexToApproved;
mapping (address => mapping (address => bool)) private ownerToAllApproved;
address public recordAddr;
string public baseTokenUri;
string public constant name = "WorldRecordCertificate";
string public constant symbol = "WRC";

uint256 public secondsPerBlock = 15;
bool public locked = true;

modifier OnlyCanTransfer(address _to) {
require(!locked || isOperator(msg.sender) || isOperator(_to),"the token is locking,can't transfer");
_;
}

bytes4 private constant _ERC721_RECEIVED = bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
bytes4 private constant _INTERFACE_ID_ERC165 = bytes4(keccak256('supportsInterface(bytes4)'));
bytes4 private constant _INTERFACE_ID_ERC721 = bytes4(keccak256('name()')) ^
bytes4(keccak256('balanceOf(address)')) ^
bytes4(keccak256('ownerOf(uint256)')) ^
bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) ^
bytes4(keccak256('safeTransferFrom(address,address,uint256)')) ^
bytes4(keccak256('transfer(address,uint256)')) ^
bytes4(keccak256('transferFrom(address,address,uint256)')) ^
bytes4(keccak256('approve(address,uint256)')) ^
bytes4(keccak256('setApprovalForAll(address,bool)')) ^
bytes4(keccak256('getApproved(uint256)')) ^
bytes4(keccak256('isApprovedForAll(address,address)')) ^
bytes4(keccak256('tokensOfOwner(address)')) ^
bytes4(keccak256('symbol()')) ^
bytes4(keccak256('tokenURI(uint256)')) ^
bytes4(keccak256('totalSupply()')) ^
bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) ^
bytes4(keccak256('tokenByIndex(uint256)'));
// bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
// bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
// bytes4 private constant _INTERFACE_ID_ERC721 = bytes4(keccak256('name()')) ^
// bytes4(keccak256('transfer(address,uint256)')) ^
// bytes4(keccak256('tokensOfOwner(address)')) ^
// bytes4(keccak256('symbol()')) ^
// bytes4(keccak256('tokenURI(uint256)')) ^
// bytes4(keccak256('totalSupply()')) ^
// bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) ^
// bytes4(keccak256('tokenByIndex(uint256)')) ^ 0x80ac58cd;

function _owns(address _owner, uint256 _tokenId) internal view returns (bool) {
return certIndexToOwner[_tokenId] == _owner;
}

function _approvedFor(address _approved, uint256 _tokenId) internal view returns (bool) {
return certIndexToApproved[_tokenId] == _approved;
}

function _approve(uint256 _tokenId, address _approved) internal {
certIndexToApproved[_tokenId] = _approved;
}

function _transfer(address _from, address _to, uint256 _tokenId) internal OnlyCanTransfer(_to){
ownerToTokenCount[_to]++;
certIndexToOwner[_tokenId] = _to;
if (_from != address(0)) {
ownerToTokenCount[_from]--;
delete certIndexToApproved[_tokenId];
}
emit Transfer(_from, _to, _tokenId);
}

function isContract(address account) internal view returns (bool) {
uint256 size;
assembly { size := extcodesize(account) }
return size > 0;
}

function _checkOnERC721Received(address _from, address _to, uint256 _tokenId, bytes memory _data) internal returns (bool){
if (!isContract(_to)) {
return true;
}
bytes4 retVal = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
return (retVal == _ERC721_RECEIVED);
}

function _exists(uint256 _tokenId) internal view returns (bool) {
return certIndexToOwner[_tokenId] != address(0);
}

function _isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns (bool) {
require(_exists(_tokenId), "ERC721: operator query for nonexistent token");
address _owner = certIndexToOwner[_tokenId];
return (isOperator(_spender) || _spender == _owner || getApproved(_tokenId) == _spender || isApprovedForAll(_owner, _spender));
}

function setLock(bool _value) onlyOwner external {
locked = _value;
}

function setSecondsPerBlock(uint256 val) onlyCLevel external{
secondsPerBlock = val;
}

function setRecordAddr(address _addr) onlyCLevel external{
recordAddr = _addr;
}

function setBaseTokenUri(string calldata str) onlyCLevel external{
baseTokenUri = str;
}

function balanceOf(address _owner) public view returns (uint256){
require(_owner != address(0),"ERC721:balance query form the zero address");
return ownerToTokenCount[_owner];
}

function burnedBalanceOf(address _owner) public view returns (uint256){
require(_owner != address(0),"ERC721:balance query form the zero address");
return ownerToBurnedTokenCount[_owner];
}

function ownerOf(uint256 _tokenId) public view returns (address _owner){
_owner = certIndexToOwner[_tokenId];
}

function burnedOwnerOf(uint256 _tokenId) public view returns (address _owner){
_owner = burnedCertIndexToOwner[_tokenId];
}

function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public payable{
require(_to != address(0));
require(_to != address(this));
transferFrom(_from, _to, _tokenId);
require(_checkOnERC721Received(_from, _to, _tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
}

function safeTransferFrom(address _from, address _to, uint256 _tokenId) public payable{
safeTransferFrom(_from, _to, _tokenId, "");
}

function transferFrom(address _from, address _to, uint256 _tokenId) public payable{
require(_to != address(0));
require(_to != address(this));
require(_isApprovedOrOwner(msg.sender, _tokenId), "ERC721: transfer caller is not owner nor approved");
_transfer(_from, _to, _tokenId);
}

function transfer(address _to, uint256 _tokenId) public {
require(_to != address(0));
require(_to != address(this));
require(_owns(msg.sender, _tokenId));
_transfer(msg.sender, _to, _tokenId);
}

function approve(address _to, uint256 _tokenId) external{
require(_owns(msg.sender, _tokenId),"ERC721:you don't have this token");
require(_to != ownerOf(_tokenId), "ERC721: approval to current owner");
_approve(_tokenId, _to);
emit Approval(msg.sender, _to, _tokenId);
}

function setApprovalForAll(address _to, bool _approved) public{
require(_to != msg.sender, "ERC721: approve to caller");
ownerToAllApproved[msg.sender][_to] = _approved;
emit ApprovalForAll(msg.sender, _to, _approved);
}

function getApproved(uint256 _tokenId) public view returns (address){
return certIndexToApproved[_tokenId];
}

function isApprovedForAll(address _owner, address _operator) public view returns (bool){
return ownerToAllApproved[_owner][_operator];
}

function tokensOfOwner(address _owner) public view returns (uint256[] memory _tokenIds){
uint256 tokenCount = balanceOf(_owner);
if (tokenCount == 0) {
return new uint256[](0);
} else {
uint256[] memory result = new uint256[](tokenCount);
uint256 totalCerts = totalSupply();
uint256 resultIndex = 0;
uint256 certId;
for (certId = 1; certId <= totalCerts; certId++) {
if (certIndexToOwner[certId] == _owner) {
result[resultIndex] = certId;
resultIndex++;
}
}
return result;
}
}

function burnTokensOfOwner(address _owner) public view returns (uint256[] memory _tokenIds){
uint256 tokenCount = ownerToBurnedTokenCount[_owner];
if (tokenCount == 0) {
return new uint256[](0);
} else {
uint256[] memory result = new uint256[](tokenCount);
uint256 totalCerts = totalSupply();
uint256 resultIndex = 0;
uint256 certId;
for (certId = 1; certId <= totalCerts; certId++) {
if (burnedCertIndexToOwner[certId] == _owner) {
result[resultIndex] = certId;
resultIndex++;
}
}
return result;
}
}

function supportsInterface(bytes4 _interfaceID) external view returns (bool){
return ((_interfaceID == _INTERFACE_ID_ERC165) || (_interfaceID == _INTERFACE_ID_ERC721));
}

function tokenURI(uint256 _tokenId) external view returns (string memory){
return strConcat(baseTokenUri, uintToString(_tokenId));
}

function totalSupply() public view returns (uint256){
return certificates.length - 1;
}

function tokenByIndex(uint256 _index) external view returns (uint256){
return _index;
}

function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256){
uint256[] memory _tokenIds = tokensOfOwner(_owner);
if(_index < _tokenIds.length){
return _tokenIds[_index];
}else{
return 0;
}
}

function getCertificateBaseInfo(uint256 _tokenId) view public returns(bool _isRecordHolder, string memory _challengeName, uint256 _recordId, string memory _value, uint256 _challengeTime, string memory _challengeLocation, string memory _videoUri, uint256 _checkTime, uint256 _pre, uint256 _later, uint256 _status){
_isRecordHolder = isRecordHolder(_tokenId);
_challengeName = certificates[_tokenId].challengeName;
_recordId = certificates[_tokenId].recordId;
_value = certificates[_tokenId].value;
_challengeTime = certificates[_tokenId].challengeTime;
_challengeLocation = certificates[_tokenId].challengeLocation;
_videoUri = certificates[_tokenId].videoUri;
_checkTime = certificates[_tokenId].checkTime;
_pre = certificates[_tokenId].pre;
_later = certificates[_tokenId].later;
_status = certificates[_tokenId].status;
}

function getCertificatePreBaseInfo(uint256 _tokenId) view public returns(bool _isRecordHolder, string memory _challengeName, uint256 _recordId, string memory _value, uint256 _challengeTime, string memory _challengeLocation, string memory _videoUri, uint256 _checkTime, uint256 _pre, uint256 _later, uint256 _status){
_tokenId = certificates[_tokenId].pre;
_isRecordHolder = isRecordHolder(_tokenId);
_challengeName = certificates[_tokenId].challengeName;
_recordId = certificates[_tokenId].recordId;
_value = certificates[_tokenId].value;
_challengeTime = certificates[_tokenId].challengeTime;
_challengeLocation = certificates[_tokenId].challengeLocation;
_videoUri = certificates[_tokenId].videoUri;
_checkTime = certificates[_tokenId].checkTime;
_pre = certificates[_tokenId].pre;
_later = certificates[_tokenId].later;
_status = certificates[_tokenId].status;
}

function getCertificateLaterBaseInfo(uint256 _tokenId) view public returns(bool _isRecordHolder, string memory _challengeName, uint256 _recordId, string memory _value, uint256 _challengeTime, string memory _challengeLocation, string memory _videoUri, uint256 _checkTime, uint256 _pre, uint256 _later, uint256 _status){
_tokenId = certificates[_tokenId].later;
_isRecordHolder = isRecordHolder(_tokenId);
_challengeName = certificates[_tokenId].challengeName;
_recordId = certificates[_tokenId].recordId;
_value = certificates[_tokenId].value;
_challengeTime = certificates[_tokenId].challengeTime;
_challengeLocation = certificates[_tokenId].challengeLocation;
_videoUri = certificates[_tokenId].videoUri;
_checkTime = certificates[_tokenId].checkTime;
_pre = certificates[_tokenId].pre;
_later = certificates[_tokenId].later;
_status = certificates[_tokenId].status;
}

function getCertificateExtraInfo(uint256 _tokenId) view public returns(string memory _remark){
_remark = certificates[_tokenId].remark;
}

function getCertificatePreExtraInfo(uint256 _tokenId) view public returns(string memory _remark){
_tokenId = certificates[_tokenId].pre;
_remark = certificates[_tokenId].remark;
}

function getCertificateLaterExtraInfo(uint256 _tokenId) view public returns(string memory _remark){
_tokenId = certificates[_tokenId].later;
_remark = certificates[_tokenId].remark;
}

function updateCertificateRemark(uint256 _tokenId, string memory _remark) onlyOperator public{
certificates[_tokenId].remark = _remark;
}

function updateCertificateValue(uint256 _tokenId, string memory _value) onlyOperator public{
certificates[_tokenId].value = _value;
}

function updateCertificatePreLater(uint256 _tokenId, uint256 _pre, uint256 _later) onlyOperator public{
certificates[_tokenId].pre = _pre;
certificates[_tokenId].later = _later;
}

function updateCertificateStatus(uint256 _tokenId, uint256 _status) onlyOperator public{
certificates[_tokenId].status = _status;
}

function isRecordHolder(uint256 _tokenId) view public returns(bool){
if(certificates[_tokenId].status != 1){
return false;
}
Certificate memory temp = certificates[_tokenId];
while(temp.later > 0){
temp = certificates[temp.later];
if(temp.status == 1){
return false;
}
}
return true;
}

function checkStatus(uint256 _certId, bool _isAgree) onlyOperator public{
require(_exists(_certId) && certificates[_certId].status == 0, "ERC721: now status is not 0");
if(_isAgree){
certificates[_certId].status = 1;
}else{
certificates[_certId].status = 2;
_burn(certIndexToOwner[_certId], _certId, certificates[_certId].pre, certificates[_certId].later, 0);
}
certificates[_certId].checkTime = now;
emit CheckResult(_certId, _isAgree);
}

function award(address _owner, string memory _value, string memory _challengeName, uint256 _recordId, uint256 _challengeTime, string memory _challengeLocation, string memory _videoUri, string memory _remark) onlyOperator public returns(uint256 _certId){
require(_owner != address(0), "ERC721:the owner is invalid");
if(_challengeTime == 0){
_challengeTime = now;
}
Certificate memory _cert = Certificate({
challengeName: _challengeName,
recordId: _recordId,
value: _value,
challengeTime: _challengeTime,
challengeLocation: _challengeLocation,
videoUri: _videoUri,
checkTime: 0,
pre: 0,
later: 0,
remark: _remark,
status: 0
});
_certId = certificates.push(_cert) - 1;
uint256 _preCertId = SimpleRecord(recordAddr).bindCertificate(_recordId, _certId);
if(_preCertId > 0){
certificates[_certId].pre = _preCertId;
certificates[_preCertId].later = _certId;
}
emit Award(_owner, _challengeName, _certId, _recordId, _value, _challengeTime, _challengeLocation, _videoUri, 0, _preCertId, _remark, 0);
_transfer(address(0), _owner, _certId);
}

function _burn(address _from, uint256 _tokenId, uint256 _preCertId, uint256 _laterCertId, uint256 _status) internal {
certIndexToOwner[_tokenId] = address(0);
if (_from != address(0)) {
ownerToTokenCount[_from]--;
delete certIndexToApproved[_tokenId];
burnedCertIndexToOwner[_tokenId] = _from;
ownerToBurnedTokenCount[_from]++;
}
emit Burned(_from, _tokenId, _preCertId, _laterCertId, _status);
}

function returnBackArgs(uint256 _tokenId, uint256 _preCertId, uint256 _laterCertId) public onlyOperator{
address _to = burnedCertIndexToOwner[_tokenId];
require(address(0) != _to,"ERC721: args are not match");
uint256 _tempStatus = certificates[_tokenId].status;
certificates[_tokenId].status = 1;

certificates[_tokenId].pre = _preCertId;
certificates[_tokenId].later = _laterCertId;

if(_preCertId > 0){
require(certificates[_preCertId].later == _laterCertId, "list relation is wrong");
certificates[_preCertId].later = _tokenId;
}
if(_laterCertId > 0){
require(certificates[_laterCertId].pre == _preCertId, "list relation is wrong");
certificates[_laterCertId].pre = _tokenId;
}
SimpleRecord(recordAddr).recoveryCertificate(certificates[_tokenId].recordId, _preCertId, _tokenId, _laterCertId);

certificates[_tokenId].checkTime = now;
burnedCertIndexToOwner[_tokenId] = address(0);
ownerToBurnedTokenCount[_to]--;
ownerToTokenCount[_to]++;
certIndexToOwner[_tokenId] = _to;
emit ReturnBack(_to, _tokenId, _preCertId, _laterCertId, _tempStatus);
}

function returnBack(uint256 _tokenId) public onlyOperator{
address _to = burnedCertIndexToOwner[_tokenId];
require(address(0) != _to,"ERC721: args are not match");
uint256 _tempStatus = certificates[_tokenId].status;
certificates[_tokenId].status = 1;

uint256 _preCertId = certificates[_tokenId].pre;
uint256 _laterCertId = certificates[_tokenId].later;

if(_preCertId > 0){
require(certificates[_preCertId].later == _laterCertId);
certificates[_preCertId].later = _tokenId;
}
if(_laterCertId > 0){
require(certificates[_laterCertId].pre == _preCertId);
certificates[_laterCertId].pre = _tokenId;
}
SimpleRecord(recordAddr).recoveryCertificate(certificates[_tokenId].recordId, _preCertId, _tokenId, _laterCertId);

certificates[_tokenId].checkTime = now;
burnedCertIndexToOwner[_tokenId] = address(0);
ownerToBurnedTokenCount[_to]--;
ownerToTokenCount[_to]++;
certIndexToOwner[_tokenId] = _to;
emit ReturnBack(_to, _tokenId, _preCertId, _laterCertId, _tempStatus);
}

function burn(uint256 _tokenId) public{
require(_isApprovedOrOwner(msg.sender, _tokenId), "ERC721: caller is not owner nor approved");

uint256 _preCertId = certificates[_tokenId].pre;
uint256 _laterCertId = certificates[_tokenId].later;
if(_preCertId > 0){
certificates[_preCertId].later = certificates[_tokenId].later;
}
if(_laterCertId > 0){
certificates[_laterCertId].pre = certificates[_tokenId].pre;
}
SimpleRecord(recordAddr).unBindCertificate(certificates[_tokenId].recordId, _preCertId, _tokenId, _laterCertId);
uint256 _tempStatus = certificates[_tokenId].status;
certificates[_tokenId].status = 4;
_burn(certIndexToOwner[_tokenId], _tokenId, _preCertId, _laterCertId, _tempStatus);
}

function () payable external{
revert();
}

constructor () public {
certificates.push(Certificate({
challengeName: "",
recordId: 0,
value: "",
challengeTime: 0,
challengeLocation: "",
videoUri: "",
checkTime: 0,
pre: 0,
later: 0,
remark: "",
status: 0
}));
}

function strConcat(string memory s1, string memory s2) pure internal returns(string memory ret){
bytes memory _bs1 = bytes(s1);
bytes memory _bs2 = bytes(s2);
string memory s12 = new string(_bs1.length + _bs2.length);
bytes memory bs12 = bytes(s12);
uint256 k = 0;
uint256 p = 0;
for (p = 0; p < _bs1.length; p++) bs12[k++] = _bs1[p];
for (p = 0; p < _bs2.length; p++) bs12[k++] = _bs2[p];
ret = string(bs12);
}

function uintToString(uint256 v) pure internal returns (string memory str) {
uint256 val = v;
uint256 maxLength = 100;
bytes memory reversed = new bytes(maxLength);
uint256 k = 0;
while (val != 0) {
uint256 remainder = val % 10;
val = val / 10;
reversed[k++] = byte(uint8(48 + remainder));
}
bytes memory s = new bytes(k + 1);
for (uint j = 0; j <= k; j++) {
s[j] = reversed[k - j];
}
str = string(s);
}
}
