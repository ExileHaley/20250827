// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script,console} from "forge-std/Script.sol";
import {Staking} from "../src/Staking.sol";
// import {DJSNfts} from "../src/DJSNfts.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract UpgradeScript is Script{
    Staking public staking;

    function setUp() public {
        staking = Staking(payable(0xFC1F7CADFEDd2a5792Ac728b044572c5Cf007776));
    }

    function run() public {
        vm.startBroadcast();

        Staking stakingV2Impl = new Staking();
        bytes memory data= "";
        staking.upgradeToAndCall(address(stakingV2Impl), data);
        vm.stopBroadcast();
        
    }
}