pragma solidity ^0.4.23;

library  StringUtil{
//    uint256 public  i = 1024;
//    function isSame(bytes memory _i) view public returns(bool _b){
//        _b = (keccak256(abi.encodePacked(toBytes(i))) == keccak256(abi.encodePacked(_i)));
//    }

    function toBytes(uint256 x) pure internal returns (bytes memory b) {
        b = new bytes(32);
        assembly { mstore(add(b, 32), x) }
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

    // function strConcat2(string _a, string _b, string _c, string _d, string _e) internal returns (string){
    //     bytes memory _ba = bytes(_a);
    //     bytes memory _bb = bytes(_b);
    //     bytes memory _bc = bytes(_c);
    //     bytes memory _bd = bytes(_d);
    //     bytes memory _be = bytes(_e);
    //     string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
    //     bytes memory babcde = bytes(abcde);
    //     uint k = 0;
    //     for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
    //     for (i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
    //     for (i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
    //     for (i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
    //     for (i = 0; i < _be.length; i++) babcde[k++] = _be[i];
    //     return string(babcde);
    // }


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

    function fromUint256(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = byte(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}
