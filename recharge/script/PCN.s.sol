// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script,console} from "forge-std/Script.sol";
import {PCN} from "../src/PCN.sol";

contract PCNScript is Script{
    PCN     public pcn;
    address public recipient;
    address public owner;

    function setUp() public {
        recipient = address(0x4605bE06cE69c944e6bc8fAD80eEeD0467867A9c);
        owner = address(0x4605bE06cE69c944e6bc8fAD80eEeD0467867A9c);
    }

    function run() public {
        vm.startBroadcast();
        pcn = new PCN(recipient);
        pcn.transferOwnership(owner);
        vm.stopBroadcast();
        console.log("recharge deployed at:",address(pcn));
    }

}