// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script,console} from "forge-std/Script.sol";
import {X101} from "../src/X101.sol";


contract X101Script is Script{
    X101 public x101;
    address sellFee;
    address initialRecipient;
    function setUp() public {
        initialRecipient = 0x3862120B1570c5D0285d15c9E0A6a38DdCf6569A;
        sellFee = 0xd6ccB8aB9351C3656063308ceF9eCE1Dc8C5b3d6;
    }

    function run() public {

        vm.startBroadcast();
        x101 = new X101(initialRecipient, sellFee);
        x101.transferOwnership(initialRecipient);
        vm.stopBroadcast();

        console.log("X101 address:", address(x101));
        console.log("Pancake pair address:", x101.pancakePair());
    }

}
