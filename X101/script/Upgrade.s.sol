// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script,console} from "forge-std/Script.sol";
import {Recharge} from "../src/Recharge.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract UpgradeScript is Script{
    Recharge public recharge;

    function setUp() public {
        recharge = Recharge(payable(0x4Bd252eD923de7B026d3cd0962487bB138294C75));
    }

    function run() public {
        vm.startBroadcast();

        Recharge rechargeV2Impl = new Recharge();
        bytes memory data= "";
        recharge.upgradeToAndCall(address(rechargeV2Impl), data);
        vm.stopBroadcast();
        
    }
}