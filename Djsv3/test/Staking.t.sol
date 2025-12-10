// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test,console} from "forge-std/Test.sol";
import {Staking} from "../src/Staking.sol";
import {LiquidityManager} from "../src/LiquidityManager.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract StakingTest is Test{
    Staking public staking;
    LiquidityManager public liquidityManager;

    
}