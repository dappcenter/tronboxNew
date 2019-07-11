pragma solidity ^0.4.23;

import "./Pausable.sol";
import "./SafeMath.sol";
import "./SimpleToken.sol";
contract SimplePool{
    function withdrawalProfit() public returns(uint256, bool);
    function getCurrentProfit() view public returns(uint256,bool);
}
contract TronBankAuction is Pausable{
    using SafeMath for uint256;

    address public poolAddr;

    address public tokenAddr;

    uint256[] public profitArray;

    uint256[] public tokenBurnArray;

    uint256 public totalProfit;

    uint256 public totalTokenBurn;

    uint256 public auctionNum = 0;

    uint256 public minInterval = 100000;

    uint256 public lastBidPrice;

    uint256 public lastBidTime;

    uint256 public lastBidBlockNumber;

    uint256 public bidEndPeriod = 600;

    mapping(address => uint256) public burnMap;

    event Bid(address indexed _bidder, uint256 _value, uint256 _totalValue, uint _auctionNum);
    event NewAuction(uint256 _totalValue, uint256 _totalBurn, uint _auctionNum);

    function setTokenAddr(address addr) onlyOperator public{
        tokenAddr = addr;
    }

    function setPoolAddr(address addr) onlyOperator public{
        poolAddr = addr;
    }

    function setMinInterval(uint256 value) onlyOperator public{
        minInterval = value;
    }

    function setBidEndPeriod(uint256 value) onlyOperator public{
        bidEndPeriod = value;
    }

    function getCurrentProfit() view public returns(uint256 _profit, bool _active){
        SimplePool p = SimplePool(poolAddr);
        (_profit, _active) = p.getCurrentProfit();
    }

    function resetLastBidTime() external onlyOperator{
        _resetLastBidTime();
    }

    function tryToResetBidTime() external onlyOperator{
        if(lastBidPrice == 0){
            _resetLastBidTime();
        }
    }

    function _resetLastBidTime() private{
        lastBidTime = block.timestamp;
        lastBidBlockNumber = block.number;
    }

    function getLastBidInfo() view public returns(uint256 _lastBidPrice, uint256 _lastBidTime, uint256 _lastBidBlockNumber){
        _lastBidPrice = lastBidPrice;
        _lastBidBlockNumber = lastBidBlockNumber;
        _lastBidTime = lastBidTime;
    }

    function newAuction() external onlyOperator returns(uint256 _profit, bool _active, uint256 _lastBidPrice, uint256 _auctionNum){
        _lastBidPrice = lastBidPrice;
        _auctionNum = auctionNum;
        _resetLastBidTime();
        if(lastBidPrice > 0){
            SimplePool p = SimplePool(poolAddr);
            (_profit, _active) = p.withdrawalProfit();
            if(_active){
                require(msg.sender.send(_profit),"transfer failed");
                SimpleToken t = SimpleToken(tokenAddr);
                t.burn(tokenBurnArray[auctionNum]);
                totalTokenBurn = totalTokenBurn.add(tokenBurnArray[auctionNum]);
                profitArray[auctionNum] = _profit;
                totalProfit = totalProfit.add(_profit);
                emit NewAuction(_profit, tokenBurnArray[auctionNum], auctionNum);
                openNew();
            }
        }
    }

    function openNew() private{
        auctionNum++;
        lastBidPrice = 0;
        profitArray.push(0);
        tokenBurnArray.push(0);
    }

    function receiveApproval(address bidder, uint256 value,address addr, bytes extraData) whenNoPaused public{
        require(addr == tokenAddr, "token address is invalid");
        require(value >= lastBidPrice.add(minInterval),"value too small");
        require(_isSame(extraData), "auctionNum is changed");
        require(block.timestamp <= lastBidTime.add(bidEndPeriod),"the auction is over,plz wait next");
        SimpleToken t = SimpleToken(tokenAddr);
        require(t.transferFrom(bidder, this, value),"transferFrom failed");

        lastBidPrice = value;
        tokenBurnArray[auctionNum] =  tokenBurnArray[auctionNum].add(value);
        burnMap[bidder] = burnMap[bidder].add(value);
        _resetLastBidTime();
        emit Bid(bidder, value, burnMap[bidder], auctionNum);
    }

    function _isSame(bytes _i) view private returns(bool _b){
        _b = (keccak256(abi.encodePacked(_toBytes(auctionNum))) == keccak256(abi.encodePacked(_i)));
    }

    function _toBytes(uint256 x) pure private returns (bytes b) {
        b = new bytes(32);
        assembly { mstore(add(b, 32), x) }
    }

    function transferTrx(address to, uint256 value) onlyOperator public{
        require(to.send(value),"transfer failed");
    }

    function () public payable{

    }

    constructor() public{
        profitArray.push(0);
        tokenBurnArray.push(0);
        _resetLastBidTime();//这么做是错误的，构造函数中无法调用其他方法
        openNew();
    }
}
