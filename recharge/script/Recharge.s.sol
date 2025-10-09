// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script,console} from "forge-std/Script.sol";
import {Recharge} from "../src/Recharge.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract RechargeScript is Script{
    Recharge public recharge;
    address public admin;
    address public recipient;

    function setUp() public {
        recipient = address(0xc94CF40E0DC051Cd5D9a2686D39871B61264093e);
        admin = address(0xA3DD4e4F035612cCC6dcE507050EB706E2A359e2);
    }

    function run() public {
        vm.startBroadcast();
        Recharge rechargeImpl = new Recharge();
        ERC1967Proxy rechargeProxy = new ERC1967Proxy(
            address(rechargeImpl),
            abi.encodeCall(rechargeImpl.initialize,(admin, recipient))
        );
        recharge = Recharge(payable(address(rechargeProxy)));
        vm.stopBroadcast();
        console.log("recharge deployed at:",address(recharge));
    }
}
