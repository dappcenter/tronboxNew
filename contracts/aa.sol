pragma solidity >=0.4.22 <0.6.0;

import "./SafeMath.sol";
import "./Address.sol";
import "./DWPausable.sol";

contract  ERC721TokenReceiver {
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
}
contract SimpleRecord{
function isRecordLast(uint256 _index) view external returns(bool);
}
contract ERC721 {
// Events
event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

function balanceOf(address _owner) public view returns (uint256 _balance);
function ownerOf(uint256 _tokenId) external view returns (address _owner);

function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) external payable;
function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
function transfer(address _to, uint256 _tokenId) external;

function approve(address _to, uint256 _tokenId) external;
function setApprovalForAll(address _operator, bool _approved) external;
function getApproved(uint256 _tokenId) external view returns (address);
function isApprovedForAll(address _owner, address _operator) external view returns (bool);

function tokensOfOwner(address _owner) external view returns (uint256[] memory _tokenIds);

// ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
function supportsInterface(bytes4 _interfaceID) external view returns (bool);
// 721Metadata
function name() external view returns (string memory _name);
function symbol() external view returns (string memory _symbol);
function tokenURI(uint256 _tokenId) external view returns (string memory);

// 721Enumerable
function totalSupply() external view returns (uint256);
function tokenByIndex(uint256 _index) external view returns (uint256);
function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}

contract DWCertificate  is DWPausable, ERC721{
using SafeMath for uint256;
using Address for address;
struct Certificate{
string challengeName;
uint256 recordId;
uint256 challengeTime;
string challengeLocation;
string videoUri;
uint256 checkTime;
string remark;
uint256 status;
}
event Mint(uint256 _certId, string _challengeName, uint256 _recordId, uint256 _challengeTime, string _challengeLocation, string _videoUri, uint256 _checkTime, string _remark, uint256 _status);
event CheckResult(uint256 _certId,uint256 _status);

Certificate[] private certificates;
mapping(uint256 => address) public certIndexToOwner;
mapping(uint256 => address) public burnedCertIndexToOwner;
mapping(address => uint256) ownerToTokenCount;
mapping(uint256 => address) public certIndexToApproved;
mapping (address => mapping (address => bool)) private ownerToAllApproved;
address public recordAddr;
string public constant name = "DouWo";
string public constant symbol = "DW";
string private baseTokenUri;
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
bytes4(keccak256('name()')) ^
bytes4(keccak256('symbol()')) ^
bytes4(keccak256('tokenURI(uint256)')) ^
bytes4(keccak256('totalSupply()')) ^
bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) ^
bytes4(keccak256('tokenByIndex(uint256)'));

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

function _checkOnERC721Received(address _from, address _to, uint256 _tokenId, bytes memory _data) internal returns (bool)
{
if (!_to.isContract()) {
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

function getBaseTokenUri() public onlyOperator view returns(string memory){
return baseTokenUri;
}

function balanceOf(address _owner) public view returns (uint256 balance){
require(_owner != address(0),"ERC721:balance query form the zero address");
return ownerToTokenCount[_owner];
}

function ownerOf(uint256 _tokenId) public view returns (address _owner){
_owner = certIndexToOwner[_tokenId];
require(owner != address(0), "ERC721: owner query for nonexistent token");
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
require(_exists(_tokenId), "ERC721: approved query for nonexistent token");
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

// ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
function supportsInterface(bytes4 _interfaceID) external view returns (bool){
return ((_interfaceID == _INTERFACE_ID_ERC165) || (_interfaceID == _INTERFACE_ID_ERC721));
}

function tokenURI(uint256 _tokenId) external view returns (string memory){
require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
return strConcat(baseTokenUri, uintToString(_tokenId));
}

// 721Enumerable
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

function getCertificateInfo(uint256 _tokenId) view public returns(string memory _challengeName, uint256 _recordId, uint256 _challengeTime, string memory _challengeLocation, string memory _videoUri, uint256 _checkTime, string memory _remark, uint256 _status){
_challengeName = certificates[_tokenId].challengeName;
_recordId = certificates[_tokenId].recordId;
_challengeTime = certificates[_tokenId].challengeTime;
_challengeLocation = certificates[_tokenId].challengeLocation;
_videoUri = certificates[_tokenId].videoUri;
_checkTime = certificates[_tokenId].checkTime;
_remark = certificates[_tokenId].remark;
_status = certificates[_tokenId].status;
}

function isRecordHolder(uint256 _tokenId) view public returns(bool){
return SimpleRecord(recordAddr).isRecordLast(certificates[_tokenId].recordId);
}

function check(uint256 _certId, uint256 _status) onlyOperator public{
certificates[_certId].status = _status;
emit CheckResult(_certId, _status);
}

function mint(address _owner, string memory _challengeName, uint256 _recordId, uint256 _challengeTime, string memory _challengeLocation, string memory _videoUri, uint256 _checkTime, string memory _remark, uint256 _status) onlyOperator public returns(uint256 _certId){
Certificate memory _cert = Certificate({
challengeName: _challengeName,
recordId: _recordId,
challengeTime: _challengeTime,
challengeLocation: _challengeLocation,
videoUri: _videoUri,
checkTime: _checkTime,
remark: _remark,
status: _status
});
_certId = certificates.push(_cert) - 1;
emit Mint(_certId, _challengeName, _recordId, _challengeTime, _challengeLocation, _videoUri, _checkTime, _remark, _status);
_transfer(address(0), _owner, _certId);
}

function _burn(address _from, uint256 _tokenId) internal {
certIndexToOwner[_tokenId] = address(0);
if (_from != address(0)) {
ownerToTokenCount[_from]--;
delete certIndexToApproved[_tokenId];
}
emit Transfer(_from, address(0), _tokenId);
}

function _burn(uint256 tokenId) internal {
_burn(ownerOf(tokenId), tokenId);
}

function burn(uint256 _tokenId) public{
require(_isApprovedOrOwner(msg.sender, _tokenId), "ERC721Burnable: caller is not owner nor approved");
_burn(_tokenId);
}

function () payable external{
revert();
}

constructor () public {

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
uint256 maxLength = 100;
bytes memory reversed = new bytes(maxLength);
uint256 k = 0;
while (v != 0) {
uint256 remainder = v % 10;
v = v / 10;
reversed[k++] = byte(uint8(48 + remainder));
}
bytes memory s = new bytes(k + 1);
for (uint j = 0; j <= k; j++) {
s[j] = reversed[k - j];
}
str = string(s);
}
}
