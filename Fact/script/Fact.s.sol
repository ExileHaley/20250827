// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script,console} from "forge-std/Script.sol";
import {Fact} from "../src/Fact.sol";


contract FactScript is Script{
    Fact public fact;

    address buyFee;
    address sellFee;
    address initialRecipient;

    function setUp() public {
        buyFee = 0xdfC967EfE061B8aA715Cce39f1A6ba47B0AB3D59;
        sellFee = 0xe98a4027Fd01e7A5F181541b4b4b56ed11B2B4C0;
        initialRecipient = 0x3D1f8Da9523f66F7b766b1d3f9502220Db90c181;
    }

    function run() public {

        vm.startBroadcast();
        fact = new Fact(initialRecipient, buyFee, sellFee);
        fact.transferOwnership(initialRecipient);
        vm.stopBroadcast();

        console.log("Fact address:", address(fact));
        console.log("Pancake pair address:", fact.pancakePair());
    }

}