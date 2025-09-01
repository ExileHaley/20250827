// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script,console} from "forge-std/Script.sol";
import {Subscribe} from "../src/Subscribe.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeploySubscribe is Script {
    Subscribe public subscribe;
    address public recipient;

    function setUp() public {
        recipient = address(0);
    }

    function run() public {
        vm.startBroadcast();
         //部署质押合约
        {
            Subscribe subscribeimpl = new Subscribe();
            ERC1967Proxy subscribeProxy = new ERC1967Proxy(
                address(subscribeimpl),
                abi.encodeCall(subscribeimpl.initialize,(recipient))
            );
            subscribe = Subscribe(payable(address(subscribeProxy)));
            
        }
        vm.stopBroadcast();
        console.log("subscribe deployed at:",address(subscribe));
    }
}
