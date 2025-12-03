// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script,console} from "forge-std/Script.sol";
import {Recharge} from "../src/Recharge.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract RechargeScript is Script {
    Recharge public recharge;
    address  public recipient;
    address  public initialCode;

    function setUp() public {
        recipient = 0x55d398326f99059fF775485246999027B3197955;
        initialCode = 0x55d398326f99059fF775485246999027B3197955;
    }

    function run() public {
        vm.startBroadcast();

        Recharge rechargeImpl = new Recharge();
        ERC1967Proxy rechargeProxy = new ERC1967Proxy(
            address(rechargeImpl),
            abi.encodeCall(rechargeImpl.initialize,(recipient, initialCode))
        );
        recharge = Recharge(payable(address(rechargeProxy)));

        vm.stopBroadcast();
        console.log("recharge deployed at:",address(recharge));
    }
}
