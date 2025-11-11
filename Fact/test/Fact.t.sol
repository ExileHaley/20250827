// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test,console} from "forge-std/Test.sol";
import {Fact} from "../src/Fact.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IUniswapV2Router02} from "../src/interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Factory} from "../src/interfaces/IUniswapV2Factory.sol";

contract FactTest is Test {
    Fact public fact;

    address buyFee;
    address sellFee;
    address initialRecipient;

    address openAddr;
    address wbnb;
    address uniswapV2Router;

    address user;

    uint256 mainnetFork;

    function setUp() public {
        mainnetFork = vm.createFork(vm.envString("rpc_url"));
        vm.selectFork(mainnetFork);

        uniswapV2Router = address(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        wbnb = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);

        buyFee = address(0x02602fDaB8Ad6b0dA6FF9cE21d0bfFA471B2f626);
        sellFee = address(0xe98a4027Fd01e7A5F181541b4b4b56ed11B2B4C0);
        initialRecipient = address(0x3D1f8Da9523f66F7b766b1d3f9502220Db90c181);

        openAddr = address(0x717Cc0E17a361c6fe16dB3238255Cda2d79f5a1A);        
              
        user = vm.addr(1);

        vm.startPrank(initialRecipient);
        fact = new Fact(initialRecipient, buyFee, sellFee);
        vm.stopPrank();
        
    }

    function test_setAllowlist() public {
        // error OwnableUnauthorizedAccount(address account);
        vm.startPrank(user);
        vm.expectRevert(
            abi.encodeWithSelector(
                bytes4(keccak256("OwnableUnauthorizedAccount(address)")),
                user
            )
        );
        fact.setAllowlist(user, true);
        vm.stopPrank();

        vm.startPrank(initialRecipient);
        fact.setAllowlist(user, true);
        vm.stopPrank();
        assertEq(fact.allowlist(user), true);
    }

    function test_addLiquidity() public {
        vm.startPrank(initialRecipient);
        uint256 amountBNB = 10e18;
        deal(initialRecipient, amountBNB);
        fact.approve(uniswapV2Router, 1000e18);

        // add liquidity
        IUniswapV2Router02(uniswapV2Router).addLiquidityETH{value:amountBNB}(
            address(fact), 
            1000e18, 
            0, 
            0, 
            initialRecipient, 
            block.timestamp + 10
        );
        
        vm.stopPrank();
        assertEq(fact.balanceOf(address(fact)), 0);
        assertEq(fact.balanceOf(fact.pancakePair()), 1000e18);
        assertEq(IERC20(wbnb).balanceOf(fact.pancakePair()), amountBNB); 
    }

    function test_sell() public {
        test_addLiquidity();
        console.log("BNB balance of initialRecipient before sell",address(initialRecipient).balance);
        vm.startPrank(initialRecipient);
        address[] memory path = new address[](2);
        path[0] = address(fact);
        path[1] = wbnb;

        fact.approve(uniswapV2Router, 100e18);
        IUniswapV2Router02(uniswapV2Router).swapExactTokensForETHSupportingFeeOnTransferTokens(
            100e18, 
            0, 
            path, 
            initialRecipient, 
            block.timestamp + 10
        );
        vm.stopPrank();
        assertEq(fact.balanceOf(fact.pancakePair()), 1100e18);
        console.log("BNB balance of initialRecipient after sell",address(initialRecipient).balance);
    }

    function test_buy_not_allowlist_failed() public {
        test_addLiquidity();
        vm.startPrank(user);
        uint256 amountBNB = 1e18;
        deal(user, amountBNB);
        address[] memory path = new address[](2);
        path[0] = wbnb;
        path[1] = address(fact);
        vm.expectRevert(bytes("Pancake: TRANSFER_FAILED"));
        IUniswapV2Router02(uniswapV2Router).swapExactETHForTokensSupportingFeeOnTransferTokens{value:amountBNB}(
            0, 
            path, 
            user, 
            block.timestamp + 10
        );
        vm.stopPrank();
    }

    function test_buy_by_openAddr() public {
        test_addLiquidity();
        vm.startPrank(openAddr);
        uint256 amountBNB = 1e18;
        deal(openAddr, amountBNB);
        address[] memory path = new address[](2);
        path[0] = wbnb;
        path[1] = address(fact);
        
        IUniswapV2Router02(uniswapV2Router).swapExactETHForTokensSupportingFeeOnTransferTokens{value:amountBNB}(
            0, 
            path, 
            openAddr, 
            block.timestamp + 10
        );
        vm.stopPrank();
    }

    function test_buy_not_allowlist_success() public {
        test_buy_by_openAddr();
        console.log("balance of user before buy:", fact.balanceOf(user));
        vm.startPrank(user);
        uint256 amountBNB = 1e18;
        deal(user, amountBNB);
        address[] memory path = new address[](2);
        path[0] = wbnb;
        path[1] = address(fact);
       
        IUniswapV2Router02(uniswapV2Router).swapExactETHForTokensSupportingFeeOnTransferTokens{value:amountBNB}(
            0, 
            path, 
            user, 
            block.timestamp + 10
        );
        vm.stopPrank();
        console.log("balance of user after buy:", fact.balanceOf(user));
    }

    function test_sell_not_allowlist_success() public {
        test_buy_by_openAddr();

        vm.startPrank(initialRecipient);
        fact.transfer(user, 100e18);
        vm.stopPrank();

      
        vm.startPrank(user);
        uint256 amount = 100e18;
        fact.approve(uniswapV2Router, amount);

        address[] memory path = new address[](2);
        path[0] = address(fact);
        path[1] = wbnb;
        
       
        IUniswapV2Router02(uniswapV2Router).swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount, 
            0, 
            path, 
            user, 
            block.timestamp + 10
        );
        vm.stopPrank();
        assertEq(fact.balanceOf(sellFee), 3e18);
    }

    function test_transfer() public {
        vm.startPrank(initialRecipient);
        fact.transfer(user, 10e18);
        vm.stopPrank();
        assertEq(fact.balanceOf(user), 10e18);

        address user1 = vm.addr(2);
        vm.startPrank(user);
        fact.transfer(user1, 10e18);
        vm.stopPrank();
        assertEq(fact.balanceOf(user), 0);
        assertEq(fact.balanceOf(user1), 10e18);
    }
}