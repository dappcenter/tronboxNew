// Abstract contract for the full ERC 20 Token standard
// https://github.com/ethereum/EIPs/issues/20
pragma solidity ^0.4.0;
import "./Operatable.sol";
import "./SafeMath.sol";

contract Manageable is Operatable{
    address public admin;
    uint256 public constant MIN_MINT_RATE = 1; // min 1:1
    uint256 public decimals = 6;
    uint256 public constant CAP = 500000000 * (10 ** 6); // total 500M, fixed amount
    uint256 public constant MINT_RATE = 60;
    uint256 public constant FUND_RATE = 10; // 10% Fund investor reward
    uint256 public constant DEV_RATE = 10; // 10% for Dev
    uint256 public constant MARKETING_RATE = 15; //15% for marketing and operations
    uint256 public constant SEED_RATE = 5; //5% for seed fund


    struct Partner {
        address addr;
        string desc;
        uint256 startDate;
        uint256 endDate; //0 means no end date
        uint256 mintRate; //per thousand
        bool isActivited;
    }

    address internal developerAccount_;
    address internal marketingAccount_;
    address internal roiAccount_;
    address internal seedAccount_;

    mapping(address => uint256) public tierOne; //tronbank contracts such as dice, game, etc.
    mapping(address => uint256) public tierTwo; //partner contracts

    Partner[] public tierOneArray;
    Partner[] public tierTwoArray;


    bool public locked = true;

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        admin = msg.sender;
        marketingAccount_ = msg.sender;
        developerAccount_ = msg.sender;
        roiAccount_ = msg.sender;
        seedAccount_ = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == owner || msg.sender == admin);
        _;
    }

    modifier onlyTier(uint256 _type) {
        require(_type == 1 || _type == 2, "Wrong tier type");
        if (_type == 1) {
            require(isTier(1, msg.sender), "only tier one contract can mint with a customized mint rate");
        } else {
            require(isTier(2, msg.sender), "Wrong contract, please double check");
        }
        _;
    }

    modifier OnlyCanTransfer(address _to) {
        require(!locked || isOperator(msg.sender) || isOperator(_to),"the token is locking,can't transfer");
        _;
    }

    function setLock(bool _value) onlyOwner public {
        locked = _value;
    }

    function setAdminAccount(address _newAdminAccount) public onlyOwner {
        require(_newAdminAccount != address(0));
        admin = _newAdminAccount;
    }

    function setMarketingAccount(address _newMarketingAccount) public onlyOwner {
        require(_newMarketingAccount != address(0));
        marketingAccount_ = _newMarketingAccount;
    }

    function getMarketingAccount() public view onlyAdmin returns (address) {
        return marketingAccount_;
    }

    function setDeveloperAccount(address _newDeveloperAccount) public onlyOwner {
        require(_newDeveloperAccount != address(0));
        developerAccount_ = _newDeveloperAccount;
    }

    function getDeveloperAccount() public view onlyAdmin returns (address) {
        return developerAccount_;
    }

    function setRoiAccount(address _newRoiAccount) public onlyOwner {
        require(_newRoiAccount != address(0));
        roiAccount_ = _newRoiAccount;
    }

    function getRoiAccount() public view onlyAdmin returns (address) {
        return roiAccount_;
    }

    function setSeedAccount(address _newSeedAccount) public onlyOwner {
        require(_newSeedAccount != address(0));
        seedAccount_ = _newSeedAccount;
    }

    function getSeedAccount() public view onlyAdmin returns (address) {
        return seedAccount_;
    }

    function isTier(uint256 _type, address _addr) public view returns (bool) {
        require(_type == 1 || _type == 2, "Wrong tier type");
        if (_type == 1) {
            return tierOne[_addr] > 0 && tierOneArray[tierOne[_addr] - 1].isActivited;
        } else {
            return tierTwo[_addr] > 0 && tierTwoArray[tierTwo[_addr] - 1].isActivited;
        }
    }

    function updateTier(uint256 _type, address _addr, string _desc, uint256 _start, uint256 _end, uint256 _mintRate, bool _activated) public onlyAdmin {
        require(_type == 1 || _type == 2, "Wrong tier type");
        require(_mintRate >= MIN_MINT_RATE, "Wrong mint rate");
        Partner[] storage tierArray;
        uint256 index = 0;
        uint256 mintRate = 0;
        //for tierOne, minRate always is 0, useless
        if (_type == 1) {
            tierArray = tierOneArray;
            index = tierOne[_addr];
        } else {
            tierArray = tierTwoArray;
            index = tierTwo[_addr];
            mintRate = _mintRate;
        }

        if (index > 0) {//existing
            tierArray[index - 1].addr = _addr;
            tierArray[index - 1].desc = _desc;
            tierArray[index - 1].startDate = _start;
            tierArray[index - 1].endDate = _end;
            tierArray[index - 1].mintRate = mintRate;
            tierArray[index - 1].isActivited = _activated;
        } else {//new
            index = tierArray.length + 1;

            tierArray.push(Partner(_addr, _desc, _start, _end, mintRate, _activated));
            if (_type == 1) {
                tierOne[_addr]=index;
            } else {
                tierTwo[_addr]=index;
            }
        }
    }

    function getTierList(uint256 _type) public view returns (address[] memory, uint256[] memory, uint256[] memory, uint256[] memory, bool[] memory) {
        require(_type == 1 || _type == 2, "Wrong tier type");
        Partner[] storage tierArray;
        if (_type == 1) {
            tierArray = tierOneArray;
        } else {
            tierArray = tierTwoArray;
        }
        address[] memory addrs = new address[](tierArray.length);
        uint256[] memory startDates = new uint256[](tierArray.length);
        uint256[] memory endDates = new uint256[](tierArray.length);
        uint256[] memory mintRates = new uint256[](tierArray.length);
        bool[] memory isActiviteds = new bool[](tierArray.length);
        for (uint256 i = 0; i < tierArray.length; i++) {
            Partner storage partner = tierArray[i];
            addrs[i] = partner.addr;
            startDates[i] = partner.startDate;
            endDates[i] = partner.endDate;
            mintRates[i] = partner.mintRate;
            isActiviteds[i] = partner.isActivited;
        }
        return
        (
        addrs,
        startDates,
        endDates,
        mintRates,
        isActiviteds
        );
    }
}

contract TRC20Interface {
    function totalSupply() public constant returns (uint);

    function balanceOf(address tokenOwner) public constant returns (uint balance);

    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);

    function transfer(address to, uint tokens) public returns (bool success);

    function approve(address spender, uint tokens) public returns (bool success);

    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


contract TRC20Token is TRC20Interface, Manageable {
    using SafeMath for uint256;
    uint256 totalSupply_;
    uint256 actualCap_;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) internal allowed;

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function actualCap() public view returns (uint256) {
        return actualCap_;
    }

    function transfer(address _to, uint256 _value) OnlyCanTransfer(_to) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transferFrom(address _from, address _to, uint256 _value) OnlyCanTransfer(_to) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        require(allowed[msg.sender][_spender] == 0);
        //avoid the potential issue caused by this function
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}

contract TNT is TRC20Token {
    string public name = "TNT - Tronbank Network Token";
    string public symbol = "TNT";
    string public version = "1.0";
    uint256 private mintedRoiTokens_;
    event onMint(address indexed to, uint256 amount);
    event onBurn(address indexed from, address indexed to, uint tokens);

    function() public {
        revert();
    }

    function getMintedValue() view public returns(uint256){
        return totalSupply_.sub(mintedRoiTokens_);
    }

    constructor() public {
        //do nothing
    }

    /* Approves and then calls the receiving contract */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

        //call the receiveApproval function on the contract you want to be notified. This crafts the function signature manually so one doesn't have to include a contract in here just for this.
        //receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
        //it is assumed that when does this that the call *should* succeed, otherwise one would use vanilla approve instead.
        if (!_spender.call(bytes4(bytes32(keccak256("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) {revert();}
        return true;
    }

    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender]);
        // no need to require value <= totalSupply, since that would imply the
        // sender's balance is greater than the totalSupply, which *should* be an assertion failure
        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        actualCap_ = actualCap_.sub(_value);
        emit onBurn(burner, address(0), _value);
    }

    function mint(uint256 _type, address _to, uint256 _amount, uint256 _mintRate) onlyTier(_type) public returns (bool) {
        uint256 tntAmount = _type == 1 ? _amount.div(_mintRate) : _amount.div(tierTwoArray[tierTwo[msg.sender] - 1].mintRate);
        require(totalSupply_.sub(mintedRoiTokens_).add(tntAmount.mul(15).div(10)) <= CAP.mul(9).div(10), "Wrong mint amount");
        _mint(_to, tntAmount);
        _mint(marketingAccount_, tntAmount.mul(MARKETING_RATE).div(MINT_RATE));
        _mint(developerAccount_, tntAmount.mul(DEV_RATE).div(MINT_RATE));
        _mint(seedAccount_, tntAmount.mul(SEED_RATE).div(MINT_RATE));
        return true;
    }

    function _mint(address _to, uint256 _amount) private {
        require(_to != address(0));
        totalSupply_ = totalSupply_.add(_amount);
        actualCap_ = actualCap_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit onMint(_to, _amount);
    }

    function getMintedRoiTokens() view onlyOwner public returns (uint256){
        return mintedRoiTokens_;
    }

    function getActualCap_() view public returns (uint256){
        return actualCap_;
    }

    function mintROI(uint256 _amount) onlyOwner public returns (bool) {
        require(mintedRoiTokens_.add(_amount) <= FUND_RATE.mul(CAP).div(100), "Wrong mint amount for ROI pool");
        mintedRoiTokens_ = mintedRoiTokens_.add(_amount);
        _mint(roiAccount_, _amount);
        return true;
    }
}

