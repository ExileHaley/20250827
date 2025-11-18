// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script,console} from "forge-std/Script.sol";
import {X101} from "../src/X101.sol";
import {Deploy} from "../src/Deploy.sol";
import {Recharge} from "../src/Recharge.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployScript is Script{
    //x101 param
    X101 public x101;
    address initialRecipient;
    address sellFee;
    
    //recharge param
    Recharge public recharge;
    address public admin;
    address public recipient;
    address public sender;
    address public percent50;
    address public percent40;
    address public percent10;

    function setUp() public {
        //x101 param init
        initialRecipient = 0x3862120B1570c5D0285d15c9E0A6a38DdCf6569A;
        sellFee = 0xd6ccB8aB9351C3656063308ceF9eCE1Dc8C5b3d6;

        //recharge param
        admin = 0x6F1fd46936b26C7685670Ec16eF403ec9B826aF9;
        recipient = 0x6cE2aeBDC5Bd15EA1fbA0e234d1147433400d4d4;
        sender = 0xF0E57eCc4a4B0FE0Cb3dd724edcE2e3122bddEE1;
        percent50 = 0xD2d0D05Ae9B339ACBbcD95E3A7210C394102f516;
        percent40 = 0x01cA5237D73D530F67c1413B4884b1A9C49D4aAb;
        percent10 = 0xF10E3cD6e824A1C169a7F6465Fd2221050154BA4;
    }

    function run() public {

        vm.startBroadcast();
        //deploy token 
        Deploy deploy = new Deploy();
        x101 = X101(deploy.deployX101(initialRecipient, sellFee));

        //deploy recharge
        Recharge rechargeImpl = new Recharge();
        ERC1967Proxy rechargeProxy = new ERC1967Proxy(
            address(rechargeImpl),
            abi.encodeCall(rechargeImpl.initialize,(admin, recipient, sender, percent50, percent40, percent10, address(x101)))
        );
        recharge = Recharge(payable(address(rechargeProxy)));

        deploy.setAllowlist(address(recharge));
        assert(x101.allowlist(address(recharge)) == true);
        deploy.transferOwnership(initialRecipient);

        vm.stopBroadcast();

        console.log("X101 deployed at:", address(x101));
        console.log("Pancake pair:", x101.pancakePair());
        console.log("Recharge deployed at:",address(recharge));
    }

}