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
        admin = 0xB791b9E7a13991371462c7A76628Ac79777e3165;
        recipient = 0x489A62c36b5B524160db74C32Ba0514c392a42E9;
        sender = 0x3Ed69DDB2e2aC7d238B8718Fcc228ae3c1E92d2F;
        initialCode = 0xB791b9E7a13991371462c7A76628Ac79777e3165;
    }

    function run() public {
        
        vm.startBroadcast();

        Staking stakingImpl = new Staking();
        ERC1967Proxy stakingProxy = new ERC1967Proxy(
            address(stakingImpl),
            abi.encodeCall(stakingImpl.initialize,(admin, recipient, sender, initialCode))
        );
        staking = Staking(payable(address(stakingProxy)));

        vm.stopBroadcast();
        console.log("staking deployed at:",address(staking));
    }
}