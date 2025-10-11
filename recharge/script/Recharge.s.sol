// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script,console} from "forge-std/Script.sol";
import {Recharge} from "../src/Recharge.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract RechargeScript is Script{
    Recharge public recharge;
    address public admin;
    address public operator;
    address public recipient;
    address public sender;

    function setUp() public {
        recipient = address(0xc94CF40E0DC051Cd5D9a2686D39871B61264093e);
        admin = address(0x7ACe9699725c246C8E26d896903779aCF579A192);
        operator = address(0x9F54d7EAbE4B64B3f6E802885A5D4Bbcb7e8BE0e);
        sender = address(0x7ACe9699725c246C8E26d896903779aCF579A192);
    }

    function run() public {
        vm.startBroadcast();
        Recharge rechargeImpl = new Recharge();
        ERC1967Proxy rechargeProxy = new ERC1967Proxy(
            address(rechargeImpl),
            abi.encodeCall(rechargeImpl.initialize,(admin, operator, recipient, sender))
        );
        recharge = Recharge(payable(address(rechargeProxy)));
        vm.stopBroadcast();
        console.log("recharge deployed at:",address(recharge));
    }
}
