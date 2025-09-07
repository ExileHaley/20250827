// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script,console} from "forge-std/Script.sol";
import {Exchange} from "../src/Exchange.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployExchange is Script{
    Exchange public exchange;

    address public cessToken;

    function setUp() public {
        //兑换合约参数初始化
        cessToken = address(0x0c78d4605c2972e5f989DE9019De1Fb00c5D3462);
    }

    function run() public {
        vm.startBroadcast();
         //部署兑换合约
        {
            Exchange exchangeImpl = new Exchange();
            ERC1967Proxy exchangeProxy = new ERC1967Proxy(
                address(exchangeImpl),
                abi.encodeCall(exchangeImpl.initialize,(cessToken, 1e18))
            );
            exchange = Exchange(payable(address(exchangeProxy)));
            
        }
        vm.stopBroadcast();
        console.log("exchange deployed at:",address(exchange));
    }
}