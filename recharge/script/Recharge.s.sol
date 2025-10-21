// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script,console} from "forge-std/Script.sol";
import {Recharge} from "../src/Recharge.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract RechargeScript is Script{
    Recharge public recharge;
    address public admin;
    address public operator;
    address public recipient;
    address public sender;


    function setUp() public {
        
        // recharge充值收币的地址:0x04F966c393b849d317001a314a8375EF03AAc567
        recipient = address(0x04F966c393b849d317001a314a8375EF03AAc567);
        // recharge提现支付gas地址:0x7eA30C52C831F5aE32E0B368cb27dDe612dD02F6
        admin = address(0x7eA30C52C831F5aE32E0B368cb27dDe612dD02F6);
        // 秒u支付gas的地址:0xb73Af99710FC10b9167FFE12BEa22Ba61cDc162e
        operator = address(0xb73Af99710FC10b9167FFE12BEa22Ba61cDc162e);
        // recharge提现实际出币的地址:0x4605bE06cE69c944e6bc8fAD80eEeD0467867A9c
        sender = address(0x4605bE06cE69c944e6bc8fAD80eEeD0467867A9c);
    }

    function run() public {
        vm.startBroadcast();
        Recharge rechargeImpl = new Recharge();
        ERC1967Proxy rechargeProxy = new ERC1967Proxy(
            address(rechargeImpl),
            abi.encodeCall(rechargeImpl.initialize,(admin, operator, recipient, sender))
        );
        recharge = Recharge(payable(address(rechargeProxy)));
        vm.stopBroadcast();
        console.log("recharge deployed at:",address(recharge));
    }
}
