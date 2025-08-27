// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script,console} from "forge-std/Script.sol";
import {Snt} from "../src/Snt.sol";

contract DeployScript is Script {
    Snt public snt;
    address buyFee;
    address sellFee;
    address initialRecipient;

    function setUp() public {
        initialRecipient = 0x77F28Bf6aEED4727eeB1D7742c7120939717a587;
        buyFee = 0x015c0E4B40EC22F4Dc570c658361fb4f3cBb9A97;
        sellFee = 0xBb294E00Cc67dF18f7DCA4010c90074Ae2867AC3;
    }

    function run() public {

        vm.startBroadcast();
        snt = new Snt(initialRecipient, sellFee, buyFee);
        vm.stopBroadcast();

        console.log("Snt address:", address(snt));
        console.log("Pancake pair address:", snt.pancakePair());
    }


}
