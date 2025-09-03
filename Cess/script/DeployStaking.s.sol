// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script,console} from "forge-std/Script.sol";
import {Staking} from "../src/Staking.sol";
import {Cfun} from "../src/Cfun.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";


contract DeployStaking is Script {
    Staking public staking;
    //代币参数
    address public initial;
    Cfun    public cfun;

    //质押合约参数
    address public cessToken;
    address public recipient;
    address public admin;
    address public signer;
    

    function setUp() public {
        //代币参数初始化
        initial = address(0x48f74550535aA6Ab31f62e8f0c00863866C8606b);

        //质押合约参数初始化
        cessToken = address(0x0c78d4605c2972e5f989DE9019De1Fb00c5D3462);
        
        recipient = address(0x48f74550535aA6Ab31f62e8f0c00863866C8606b);
        admin = address(0x48f74550535aA6Ab31f62e8f0c00863866C8606b);
        signer = address(0xD93dbbaB274F870CE2ab0539b56F3c8329db2DF9);
    }

    function run() public {
        vm.startBroadcast();
        //部署代币cfun
        {   
            cfun = new Cfun(initial);
        }
        address[] memory addrs = new address[](1);
        addrs[0] = address(0x48f74550535aA6Ab31f62e8f0c00863866C8606b);
         //部署质押合约
        {
            Staking stakingImpl = new Staking();
            ERC1967Proxy stakingProxy = new ERC1967Proxy(
                address(stakingImpl),
                abi.encodeCall(stakingImpl.initialize,(cessToken, address(cfun), recipient, admin, signer, addrs))
            );
            staking = Staking(payable(address(stakingProxy)));
            
        }
        vm.stopBroadcast();
        console.log("cfun deployed at:",address(cfun));
        console.log("staking deployed at:",address(staking));
    }
}
