// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Skp} from "../src/Skp.sol";
import {IUniswapV2Router02} from "../src/interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Factory} from "../src/interfaces/IUniswapV2Factory.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract SkpTest is Test{
    Skp public skp;
    address initialRecipient;
    address sellFee;

    address user;
    address user1;
    address public USDT;
    address public uniswapV2Router;

    uint256 mainnetFork;

    function setUp() public {
        mainnetFork = vm.createFork(vm.envString("rpc_url"));
        vm.selectFork(mainnetFork);
        //mainnet address
        uniswapV2Router = address(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        USDT = address(0x55d398326f99059fF775485246999027B3197955);
        
        //init address
        initialRecipient = vm.addr(1);
        sellFee = vm.addr(2);
        user = vm.addr(6);
        user1 = vm.addr(7);


        vm.startPrank(initialRecipient);
        skp = new Skp(initialRecipient, sellFee);
        vm.stopPrank();

        addLiquidity_allowlist();
    }

    function addLiquidity_allowlist() internal{
        vm.startPrank(initialRecipient);
        deal(USDT, initialRecipient, 10000e18);

        skp.approve(uniswapV2Router, 10000e18);
        IERC20(USDT).approve(uniswapV2Router, 10000e18);

        IUniswapV2Router02(uniswapV2Router).addLiquidity(
            address(skp), 
            USDT, 
            10000e18, 
            10000e18, 
            0, 
            0, 
            initialRecipient, 
            block.timestamp + 10
        );

        vm.stopPrank();
        assertEq(skp.balanceOf(skp.pancakePair()), 10000e18);
    }

    function test_sell_not_allowlist() public {
        vm.startPrank(initialRecipient);
        skp.transfer(user, 101e18);
        vm.stopPrank();

        vm.startPrank(user);
        skp.approve(uniswapV2Router, 100e18);
        address[] memory path = new address[](2);
        path[0] = address(skp);
        path[1] = USDT;
        IUniswapV2Router02(uniswapV2Router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            100e18, 
            0, 
            path, 
            user, 
            block.timestamp + 10
        );
        vm.stopPrank();
        console.log("usdt balance of sell fee:",IERC20(USDT).balanceOf(sellFee));

    }

}