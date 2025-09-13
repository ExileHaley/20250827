// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {Staking} from "../src/Staking.sol";
import {Destroy} from "../src/Destroy.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployScript is Script{
    Staking public staking;
    Destroy public destroy;

    address flapToken;
    address subToken;

    function setUp() public {
        flapToken = address(0xFE48dFE764e9E9bBeB8C84D70fe710013C681111);
        subToken = address(0xFE48dFE764e9E9bBeB8C84D70fe710013C681111);
    }

    function run() public {
        vm.startBroadcast();
        //部署质押合约
        {
            Staking stakingImpl = new Staking();
            ERC1967Proxy stakingProxy = new ERC1967Proxy(
                address(stakingImpl),
                abi.encodeCall(stakingImpl.initialize,(flapToken, subToken))
            );
            staking = Staking(payable(address(stakingProxy)));
        }
        
        //部署销毁合约
        {
            Destroy destroyImpl = new Destroy();
            ERC1967Proxy destroyProxy = new ERC1967Proxy(
                address(destroyImpl),
                abi.encodeCall(destroyImpl.initialize,(flapToken, subToken))
            );
            destroy = Destroy(payable(address(destroyProxy)));
        }

        vm.stopBroadcast();
    }

}