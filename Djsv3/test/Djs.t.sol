// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test,console} from "forge-std/Test.sol";

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {NodeDividends} from "../src/NodeDividends.sol";
import {Djs} from "../src/Djs.sol";

contract DjsTest is Test{
    NodeDividends public    nodeDividends;
    address       public    nfts;

    Djs     public    djs;
    address public    marketing;
    address public    wallet;

    


   
}
