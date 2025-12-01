// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script,console} from "forge-std/Script.sol";
import {Recharge} from "../src/Recharge.sol";
import {Skp} from "../src/Skp.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployScript is Script{
    //recharge param
    Recharge public recharge;
    address admin;
    address recipient;
    address sender;
    address percent50;
    address percent30;
    address percent20;
    Skp public  skp;
    address buyBackPercent538;
    // address buyBackPercent362;
    address buyBackPercent2;

    //skp param
    address public initialRecipient;
    address public sellFee;



    function setUp() public {
        //recharge param init
        admin = 0x4f1cc0A7c85329a34f7d6aBd54c296b6175C36AD; 

        recipient = 0x438003F621cB1bfE2a1FB7DFE02962b0455e5675;

        sender = 0x07970cABEBAc60e6558Db03871902a9F8Bc63BF9; 

        percent50 = 0x438003F621cB1bfE2a1FB7DFE02962b0455e5675;
        percent30 = 0xeC94798493243C69Dc627770E4f3edCFD1f78bE0;
        percent20 = 0x5D8d24DC99Ae142B432ACb3bc509758578900296;
        buyBackPercent538 = 0xeC94798493243C69Dc627770E4f3edCFD1f78bE0;
        // address buyBackPercent362;
        buyBackPercent2 = 0xAF84D6a073bBbc678899671b9BA3669811018982;

        //skp param init
        initialRecipient = 0xD4360fAE9a810Be17b5fC1edF12849675996f712;
        sellFee = 0x73832D01364c48e4b6C49B9ECBF07aB92852B67c;
    }

    function run() public {
        vm.startBroadcast();
        //fact deploy
        skp = new Skp(initialRecipient, sellFee);
        //recharge deploy
        Recharge rechargeImpl = new Recharge();

        ERC1967Proxy rechargeProxy = new ERC1967Proxy(
            address(rechargeImpl),
            abi.encodeCall(rechargeImpl.initialize,(admin, recipient, sender, percent50, percent30, percent20, address(skp), buyBackPercent538, skp.pancakePair(), buyBackPercent2))
        );
        recharge = Recharge(payable(address(rechargeProxy)));

        //设置白名单和转移权限
        skp.setAllowlist(address(recharge), true);
        skp.transferOwnership(initialRecipient);

        vm.stopBroadcast();

        console.log("Skp address:", address(skp));
        console.log("Pancake pair address:", skp.pancakePair());
        console.log("recharge deployed at:",address(recharge));
    }

}

