// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script,console} from "forge-std/Script.sol";
import {Staking} from "../src/Staking.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract StakingScript is Script {

    Staking public staking;
    
    address public admin;
    address public recipient;
    address public sender;
    address public initialCode;
    function setUp() public {
        admin = 0x7c5d474234CE010B01f1C674542DCeBaa1bEAd41;
        recipient = 0x32FE505B0aF6d8672F864abd26f93d35a82b0a5a;
        initialCode = 0x32FE505B0aF6d8672F864abd26f93d35a82b0a5a;
    }

    function run() public {
        
        vm.startBroadcast();

        Staking stakingImpl = new Staking();
        ERC1967Proxy stakingProxy = new ERC1967Proxy(
            address(stakingImpl),
            abi.encodeCall(stakingImpl.initialize,(admin, recipient, initialCode))
        );
        staking = Staking(payable(address(stakingProxy)));

        vm.stopBroadcast();
        console.log("staking deployed at:",address(staking));
    }
}