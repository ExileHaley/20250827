// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script,console} from "forge-std/Script.sol";
import {SubscribeV2} from "../src/SubscribeV2.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeploySubscribeV2 is Script {
    SubscribeV2 public subscribe;
    address public recipient;

    function setUp() public {
        //
        recipient = address(0xAeF1A82D6f70574741690B3E4C9296f3611C6deC);
    }

    function run() public {
        vm.startBroadcast();
         //部署质押合约
        {
            SubscribeV2 subscribeimpl = new SubscribeV2();
            ERC1967Proxy subscribeProxy = new ERC1967Proxy(
                address(subscribeimpl),
                abi.encodeCall(subscribeimpl.initialize,(recipient))
            );
            subscribe = SubscribeV2(payable(address(subscribeProxy)));
            
        }
        vm.stopBroadcast();
        console.log("subscribe deployed at:",address(subscribe));
    }
}
