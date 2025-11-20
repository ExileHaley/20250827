// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script,console} from "forge-std/Script.sol";
import {RechargeDst} from "../src/RechargeDst.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract RechargeDstScript is Script{
    RechargeDst public recharge;
    address public admin;
    address public percent50;
    address public percent38;
    address public percent12;
    address public sender;

    function setUp() public {
        admin       = address(0x3Cd7abf964D3717EFeB4651D133058f0A4a2105f);
        percent50   = address(0x64Cd2aed635CE50fFF0D826C0b0ad54d1c195261);
        percent38   = address(0x33Fc6D43bd91ecF04167ed453dEC0AdeA9502369);
        percent12   = address(0x1d31f8f3e8871b4b822E50F29d0f8cb1706A5504);
        sender      = address(0x538c821C3006935e730114d6a2c3A1Ac7Ce1e3Bb);
    }

    function run() public {
        vm.startBroadcast();
        RechargeDst rechargeImpl = new RechargeDst();
        ERC1967Proxy rechargeProxy = new ERC1967Proxy(
            address(rechargeImpl),
            abi.encodeCall(rechargeImpl.initialize,(admin, percent50, percent38, percent12, sender))
        );
        recharge = RechargeDst(payable(address(rechargeProxy)));
        vm.stopBroadcast();
        console.log("recharge dst deployed at:",address(recharge));
    }
}
