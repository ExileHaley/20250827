// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script,console} from "forge-std/Script.sol";
import {Recharge} from "../src/Recharge.sol";
import {DJSNfts} from "../src/DJSNfts.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployScript is Script {

    Recharge public recharge;
    address  public recipient;
    address  public initialCode;
    string   public baseURI;

    DJSNfts public nfts;

    function setUp() public {
        recipient = 0xB791b9E7a13991371462c7A76628Ac79777e3165;
        initialCode = 0xB791b9E7a13991371462c7A76628Ac79777e3165;
        baseURI = "";
    }

    function run() public {
        
        vm.startBroadcast();

        nfts = new DJSNfts();

        Recharge rechargeImpl = new Recharge();
        ERC1967Proxy rechargeProxy = new ERC1967Proxy(
            address(rechargeImpl),
            abi.encodeCall(rechargeImpl.initialize,(recipient, initialCode, address(nfts)))
        );
        recharge = Recharge(payable(address(rechargeProxy)));
        nfts.setRecharge(address(recharge));
        nfts.setBaseURI(baseURI);
        vm.stopBroadcast();
        console.log("Nfts deployed at:",address(nfts));
        console.log("recharge deployed at:",address(recharge));
    }
}
