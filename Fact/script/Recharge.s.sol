// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script,console} from "forge-std/Script.sol";
import {Recharge} from "../src/Recharge.sol";
import {Fact} from "../src/Fact.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";


contract RechargeScript is Script{
    //recharge data
    Recharge public recharge;
    address public admin;
    address public recipient;
    address public sender;
    address public percent100;

    //fact data
    Fact    public fact;
    address public buyFee;
    address public sellFee;
    address public initialRecipient;

    function setUp() public {
        //recharge data init
        admin = address(0x39BD0a3E2c70CeE992B11F5Ca12f10489a53C53D);
        recipient = address(0xbA06d6F5A24E2dB7D03F47608Ad3f24Cb7b3B3c5);
        sender = address(0xd04A371DC58D7c66574D38Afa763e4D1C71d6F8a);
        percent100 = address(0x7b8865D82c21CE764b27718151fF4097e626462C);

        //fact data init 
        buyFee = 0xbA06d6F5A24E2dB7D03F47608Ad3f24Cb7b3B3c5;
        sellFee = 0xbA06d6F5A24E2dB7D03F47608Ad3f24Cb7b3B3c5;
        initialRecipient = 0x3D1f8Da9523f66F7b766b1d3f9502220Db90c181;
    }

    function run() public {
        vm.startBroadcast();
        //fact deploy
        fact = new Fact(initialRecipient, buyFee, sellFee);
        //recharge deploy
        Recharge rechargeImpl = new Recharge();
        ERC1967Proxy rechargeProxy = new ERC1967Proxy(
            address(rechargeImpl),
            abi.encodeCall(rechargeImpl.initialize,(admin, recipient, sender, percent100, address(fact)))
        );
        recharge = Recharge(payable(address(rechargeProxy)));

        //设置白名单和转移权限
        fact.setAllowlist(address(recharge), true);
        fact.transferOwnership(initialRecipient);

        vm.stopBroadcast();

        console.log("Fact address:", address(fact));
        console.log("Pancake pair address:", fact.pancakePair());
        console.log("recharge deployed at:",address(recharge));
    }

}