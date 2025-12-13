// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script,console} from "forge-std/Script.sol";
import {Recharge} from "../src/Recharge.sol";
import {Skp} from "../src/Skp.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract UpgradeScript is Script{
    Recharge public recharge;

    function setUp() public {
        recharge = Recharge(payable(0x9f4D2f16a3bfEC4FD9247c8d2440A0c70ed24Af8));
    }

    function run() public {
        vm.startBroadcast();

        Recharge rechargeV2Impl = new Recharge();
        bytes memory data= "";
        recharge.upgradeToAndCall(address(rechargeV2Impl), data);
        vm.stopBroadcast();
        
    }
}