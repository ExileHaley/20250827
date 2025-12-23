// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script,console} from "forge-std/Script.sol";
import {Recharge} from "../src/Recharge.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract UpgradeScript is Script {
    Recharge public recharge;

    function setUp() public {
        recharge = Recharge(payable(0x7FC2f5A3428F8e2a539caF52f83c8EDECa12985f));
    }

    function run() public {
        vm.startBroadcast();

        Recharge rechargeV2Impl = new Recharge();
        bytes memory data= "";
        recharge.upgradeToAndCall(address(rechargeV2Impl), data);
        vm.stopBroadcast();
    
    }
}