// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test,console} from "forge-std/Test.sol";
import {Snt} from "../src/Snt.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IUniswapV2Router} from "../src/interfaces/IUniswapV2Router.sol";

contract SntTest is Test {
    Snt public snt;

    address buyFee;
    address sellFee;
    address initialRecipient;

    address user;
    address public usdt;
    address public uniswapV2Router;

    uint256 mainnetFork;

    function setUp() public {
        mainnetFork = vm.createFork(vm.envString("rpc_url"));
        vm.selectFork(mainnetFork);

        uniswapV2Router = address(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        usdt = address(0x55d398326f99059fF775485246999027B3197955);
        // dead = 0x000000000000000000000000000000000000dEaD;
        buyFee = 0x015c0E4B40EC22F4Dc570c658361fb4f3cBb9A97;
        sellFee = 0xBb294E00Cc67dF18f7DCA4010c90074Ae2867AC3;
        
        user = vm.addr(1);
        initialRecipient = vm.addr(2);

        vm.startPrank(initialRecipient);
        snt = new Snt(initialRecipient, sellFee, buyFee);
        vm.stopPrank();
        
    }

    function test_addLiquidity() public {
        
        vm.startPrank(initialRecipient);
        snt.switchBurn();
        deal(usdt, initialRecipient, 10000e18);
        snt.approve(uniswapV2Router, 10000e18);
        IERC20(usdt).approve(uniswapV2Router, 10000e18);

        IUniswapV2Router(uniswapV2Router).addLiquidity(
            usdt, 
            address(snt), 
            10000e18, 
            10000e18, 
            0, 
            0, 
            initialRecipient, 
            block.timestamp + 10
        );
        vm.stopPrank();

        assertEq(snt.balanceOf(address(snt)), 0);
        uint256 fee = 10000e18 * 3 / 100;
        assertEq(snt.balanceOf(snt.pancakePair()), 10000e18 - fee);
        assertEq(snt.balanceOf(sellFee), fee);
    }



    function test_burnAfter10Minutes() public {
        // --- Step1: 添加初始流动性 ---
        test_addLiquidity();  

        uint256 before = snt.balanceOf(snt.pancakePair());

        // 连续 3 轮验证，每轮推进 11 分钟后触发一次转账
        for (uint256 i = 0; i < 3; i++) {
            // --- Step2: 时间推进 ---
            vm.warp(block.timestamp + 11 minutes);

            // --- Step3: 用户转账触发销毁 ---
            vm.startPrank(user);
            deal(address(snt), user, 100e18);
            snt.transfer(initialRecipient, 10e18);
            vm.stopPrank();

            // --- Step4: 验证 ---
            uint256 afterBal = snt.balanceOf(snt.pancakePair());
            assertLt(afterBal, before, string(abi.encodePacked("Round ", vm.toString(i), ": LP should have burned some SNT")));
            
            // 更新基准值
            before = afterBal;
        }
    }

    function test_buy() public{
        test_addLiquidity();
        vm.startPrank(user);
        address[] memory path = new address[](2);
        path[0] = usdt;
        path[1] = address(snt);
        deal(usdt, user, 50e18);
        IERC20(usdt).approve(uniswapV2Router, 50e18);
        IUniswapV2Router(uniswapV2Router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            50e18, 
            0, 
            path, 
            user, 
            block.timestamp
        );
        vm.stopPrank();
    }

    function test_sell() public {
        test_addLiquidity();

        vm.startPrank(initialRecipient);
        snt.transfer(user, 50e18);
        vm.stopPrank();

        vm.startPrank(user);
        address[] memory path = new address[](2);
        path[0] = address(snt);
        path[1] = usdt;
        
        snt.approve(uniswapV2Router, 50e18);
        IUniswapV2Router(uniswapV2Router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            50e18, 
            0, 
            path, 
            user, 
            block.timestamp
        );
        vm.stopPrank();
    }

    function test_buyAfter10Mitunes() public {
        test_addLiquidity();  
        vm.warp(block.timestamp + 11 minutes);

        vm.startPrank(user);
        address[] memory path = new address[](2);
        path[0] = usdt;
        path[1] = address(snt);
        deal(usdt, user, 50e18);
        IERC20(usdt).approve(uniswapV2Router, 50e18);
        IUniswapV2Router(uniswapV2Router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            50e18, 
            0, 
            path, 
            user, 
            block.timestamp
        );
        vm.stopPrank();
    }

}
