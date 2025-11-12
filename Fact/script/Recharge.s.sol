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

    //fact data
    Fact    public fact;
    address public buyFee;
    address public sellFee;
    address public initialRecipient;

    function setUp() public {
        //recharge data init
        admin = address(0x39BD0a3E2c70CeE992B11F5Ca12f10489a53C53D);
        recipient = address(0x02602fDaB8Ad6b0dA6FF9cE21d0bfFA471B2f626);
        sender = address(0x19621484D92031BfcDA0DE53920B25FE514A3c12);

        //fact data init 
        buyFee = 0x02602fDaB8Ad6b0dA6FF9cE21d0bfFA471B2f626;
        sellFee = 0xe98a4027Fd01e7A5F181541b4b4b56ed11B2B4C0;
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
            abi.encodeCall(rechargeImpl.initialize,(admin, recipient, sender, address(fact)))
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