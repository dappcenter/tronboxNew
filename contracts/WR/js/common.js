App = {
    web3Provider: null,
    contracts: {},
    spender: null,
    spenderContract : null,
    defaultAccount : null,
    erc20ABI :[{"constant":true,"inputs":[],"name":"name","outputs":[{"name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"_spender","type":"address"},{"name":"_value","type":"uint256"}],"name":"approve","outputs":[{"name":"success","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"totalSupply","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"_from","type":"address"},{"name":"_to","type":"address"},{"name":"_value","type":"uint256"}],"name":"transferFrom","outputs":[{"name":"success","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"decimals","outputs":[{"name":"","type":"uint8"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"version","outputs":[{"name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"_spender","type":"address"},{"name":"_subtractedValue","type":"uint256"}],"name":"decreaseApproval","outputs":[{"name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[{"name":"_owner","type":"address"}],"name":"balanceOf","outputs":[{"name":"balance","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"symbol","outputs":[{"name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"_to","type":"address"},{"name":"_value","type":"uint256"}],"name":"transfer","outputs":[{"name":"success","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"_spender","type":"address"},{"name":"_value","type":"uint256"},{"name":"_extraData","type":"bytes"}],"name":"approveAndCall","outputs":[{"name":"success","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"_spender","type":"address"},{"name":"_addedValue","type":"uint256"}],"name":"increaseApproval","outputs":[{"name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[{"name":"_owner","type":"address"},{"name":"_spender","type":"address"}],"name":"allowance","outputs":[{"name":"remaining","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"inputs":[],"payable":false,"stateMutability":"nonpayable","type":"constructor"},{"payable":false,"stateMutability":"nonpayable","type":"fallback"},{"anonymous":false,"inputs":[{"indexed":true,"name":"_from","type":"address"},{"indexed":true,"name":"_to","type":"address"},{"indexed":false,"name":"_value","type":"uint256"}],"name":"Transfer","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"_owner","type":"address"},{"indexed":true,"name":"_spender","type":"address"},{"indexed":false,"name":"_value","type":"uint256"}],"name":"Approval","type":"event"}],
    multiSendABI :
        [
            {
                "constant": false,
                "inputs": [
                    {
                        "name": "tokenaddr",
                        "type": "address"
                    },
                    {
                        "name": "tos",
                        "type": "address[]"
                    },
                    {
                        "name": "value",
                        "type": "uint256"
                    }
                ],
                "name": "multiTransferToken",
                "outputs": [
                    {
                        "name": "",
                        "type": "bool"
                    }
                ],
                "payable": true,
                "stateMutability": "payable",
                "type": "function"
            },
            {
                "constant": false,
                "inputs": [
                    {
                        "name": "tokenaddr",
                        "type": "address"
                    },
                    {
                        "name": "tos",
                        "type": "address[]"
                    },
                    {
                        "name": "value",
                        "type": "uint256[]"
                    }
                ],
                "name": "multiTransferTokenValues",
                "outputs": [
                    {
                        "name": "",
                        "type": "bool"
                    }
                ],
                "payable": true,
                "stateMutability": "payable",
                "type": "function"
            },


            {
                "constant": true,
                "inputs": [
                    {
                        "name": "",
                        "type": "address"
                    },
                    {
                        "name": "toCnt",
                        "type": "uint256"
                    },
                    {
                        "name": "",
                        "type": "uint256"
                    },
                    {
                        "name": "gasprice",
                        "type": "uint256"
                    }
                ],
                "name": "guessGasView",
                "outputs": [
                    {
                        "name": "",
                        "type": "uint256"
                    }
                ],
                "payable": false,
                "stateMutability": "pure",
                "type": "function"
            },
            {
                "constant": true,
                "inputs": [
                    {
                        "name": "tokenaddr",
                        "type": "address"
                    },
                    {
                        "name": "toCnt",
                        "type": "uint256"
                    },
                    {
                        "name": "ttvalue",
                        "type": "uint256"
                    },
                    {
                        "name": "gasprice",
                        "type": "uint256"
                    }
                ],
                "name": "guessGasWithValuesView",
                "outputs": [
                    {
                        "name": "",
                        "type": "uint256"
                    }
                ],
                "payable": false,
                "stateMutability": "pure",
                "type": "function"
            },

            {
                "constant": true,
                "inputs": [],
                "name": "isOpen",
                "outputs": [
                    {
                        "name": "",
                        "type": "bool"
                    }
                ],
                "payable": false,
                "stateMutability": "view",
                "type": "function"
            }

        ],
    web3js : null,
    gaspriceInGWei : 0,
    init: function() {
        return App.initWeb3();
    },

    initWeb3: function() {
        if(typeof web3 !== 'undefined'){
            App.web3Provider = web3.currentProvider;
        }else{
            App.web3Provider = new Web3.providers.HttpProvider('http://localhost:8545');
        }
        App.web3js = new Web3(App.web3Provider);

        return App.checkConnected();
    },
    checkConnected : function(){
        if (!App.web3js || !App.web3js.isConnected()){
            alert("No MetaMask or connected node. You cannot send transaction.");
            return false;
        }
        App.setSpenderContractAddress();
        return true;
    },
    setSpenderContractAddress : function(){
        if (App.web3js.version.network==1){
            App.spender = '0x41b7cf5bf7d0003d836e5ef4b17689c49c6620b8';//上线后变成mainAddress
        }else if (App.web3js.version.network==3){
            App.spender = '0x41b7cf5bf7d0003d836e5ef4b17689c49c6620b8';
        }else{
            alert(" Unknown net:"+App.web3js.version.network);
            return;
        }
        return App.checkOpen();
    },
    checkOpen: function() {
        App.spenderContract = App.web3js.eth.contract(App.multiSendABI).at(App.spender);
        App.spenderContract.isOpen(function(err,res){
            console.log("isOpen:" + res);
            if (err){
                alert("failed to check if we can run contract at spender:"+App.spender+", error:"+err);
                return;
            }
            if (!res){
                alert("The contract is not Open for use at now.");
                return;
            }
            App.setDefaultAccount();
        });
    },
    setDefaultAccount: function(){
        App.web3js.eth.getAccounts(function(error, accounts){
            if(error){
                alert("fail to get default account, error:" + error);
                return;
            }
            App.defaultAccount = accounts[0];
        });
    },
    checkERC20Addr : function(address) {
        //方法地址，转成js
        //https://blog.csdn.net/wypeng2010/article/details/81325762?utm_source=blogxgwz1
    },
    getTokenContract :function(address){
        return App.web3js.eth.contract(App.erc20ABI).at(address);
    },
    refreshGasPrice : function(){
        App.web3js.eth.getGasPrice(function(err,res){
            if (err){
                alert("cannot get mediem gas price: "+err);
                return;
            }
            App.gaspriceInGWei = App.web3js.fromWei(res,"gwei").toNumber() + 1;
        });
    }
};

$(function() {
    $(window).load(function() {
        App.init();
    });
});
