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

// 独角兽项目正式地址
// 给我一个头部地址，用来向下邀请：0x681be3bA6D85Ff7Ed459372a3aEEEdf43c7Aa37d
// 还有一个venus token的接收地址：0xdCC65e89485b458deFd8D038De6D6fC16a27dCE5

    function setUp() public {
        recipient = 0xdCC65e89485b458deFd8D038De6D6fC16a27dCE5;
        initialCode = 0x681be3bA6D85Ff7Ed459372a3aEEEdf43c7Aa37d;
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
