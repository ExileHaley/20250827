// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test,console} from "forge-std/Test.sol";

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IUniswapV2Router02} from "../src/interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Factory} from "../src/interfaces/IUniswapV2Factory.sol";
import {NodeDividends} from "../src/NodeDividends.sol";
import {Djs} from "../src/Djs.sol";

contract DjsTest is Test{
    NodeDividends public    nodeDividends;
    address       public    nfts;

    Djs     public    djs;
    address public    initialRecipient;
    address public    marketing;
    address public    wallet;
    address public    owner;


    address public user;
    address public user1;

    address public USDT;
    address public uniswapV2Router;


    uint256 mainnetFork;    
    function setUp() public {
        mainnetFork = vm.createFork(vm.envString("rpc_url"));
        vm.selectFork(mainnetFork);
        //mainnet address
        uniswapV2Router = address(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        USDT = address(0x55d398326f99059fF775485246999027B3197955);

        nfts = address(1);
        initialRecipient = address(2);
        marketing = address(3);
        wallet = address(4);
        owner = address(5);
        user = address(6);
        user1 = address(7);

        vm.startPrank(owner);
        djs = new Djs(initialRecipient, marketing, wallet);

        NodeDividends nodeImpl = new NodeDividends();
        ERC1967Proxy nodeProxy = new ERC1967Proxy(
            address(nodeImpl),
            abi.encodeCall(nodeImpl.initialize,(address(nfts), address(djs)))
        );
        nodeDividends = NodeDividends(payable(address(nodeProxy)));
        djs.setNodeDividends(address(nodeDividends));

        djs.setTradingOpen(true);

        vm.stopPrank();
        addLiquidity_allowlist();

    }

    function addLiquidity_allowlist() internal{
        vm.startPrank(initialRecipient);
        deal(USDT, initialRecipient, 10000e18);

        djs.approve(uniswapV2Router, 10000e18);
        IERC20(USDT).approve(uniswapV2Router, 10000e18);

        IUniswapV2Router02(uniswapV2Router).addLiquidity(
            address(djs), 
            USDT, 
            10000e18, 
            10000e18, 
            0, 
            0, 
            initialRecipient, 
            block.timestamp + 10
        );

        vm.stopPrank();
        assertEq(djs.balanceOf(djs.pancakePair()), 10000e18);
    }

    function _swap(address addr, address fromToken, address toToken, uint256 fromAmount) internal{
        vm.startPrank(addr);
        IERC20(fromToken).approve(uniswapV2Router, fromAmount);
        address[] memory path = new address[](2);
        path[0] = fromToken;
        path[1] = toToken;
        IUniswapV2Router02(uniswapV2Router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            fromAmount, 
            0, 
            path, 
            addr, 
            block.timestamp + 10
        );
        vm.stopPrank();
    }

    function test_buy_not_allowlist_cost() public {

        deal(USDT, user, 100e18);
        _swap(user, USDT, address(djs), 100e18);

        uint256 oneHalf = djs.balanceOf(user) / 2;
        //转移时将相应的成本给user1
        vm.startPrank(user);
        djs.transfer(user1, oneHalf);
        vm.stopPrank();
    }

    function test_sell_not_allowlist_profit() public {

        deal(USDT, user, 100e18);
        _swap(user, USDT, address(djs), 100e18);
        console.log("Before sell usdt balance of marketing=:",IERC20(USDT).balanceOf(djs.marketing()));
        console.log("Before sell usdt balance of wallet=:",IERC20(USDT).balanceOf(djs.wallet()));

        deal(USDT, user1, 1000e18);
        _swap(user1, USDT, address(djs), 1000e18);

        console.log("Before sell usdt balance of marketing==:",IERC20(USDT).balanceOf(djs.marketing()));
        console.log("Before sell usdt balance of wallet==:",IERC20(USDT).balanceOf(djs.wallet()));

        uint256 amountToken = djs.balanceOf(user);
        _swap(user, address(djs), USDT, amountToken);

        console.log("After sell usdt balance of marketing===:",IERC20(USDT).balanceOf(djs.marketing()));
        console.log("After sell usdt balance of wallet===:",IERC20(USDT).balanceOf(djs.wallet()));

    }  

    // ---------------------- 买入相关 ----------------------

    // 买入地址在 allowlist，不触发 swap 税，成本是否记录
    function test_buy_allowlist_no_fee() public {
        vm.startPrank(owner);
        djs.setTradingOpen(true);
        vm.stopPrank();

        deal(USDT, initialRecipient, 100e18);
        _swap(initialRecipient, USDT, address(djs), 100e18);
        assertEq(djs.totalCostUsdt(initialRecipient), 0);
        // console.log("Cost after buy for allowlist:", djs.totalCostUsdt(initialRecipient));
    }

    // 买入金额极大，测试溢出风险
    function test_buy_large_amount() public {
        vm.startPrank(owner);
        djs.setTradingOpen(true);
        vm.stopPrank();

        deal(USDT, user, 5000e18); // 1亿 DJS
        _swap(user, USDT, address(djs), 5000e18);

        console.log("Balance of user after huge buy:", djs.balanceOf(user));
        console.log("Total cost USDT:", djs.totalCostUsdt(user));
    }

    // ---------------------- 卖出相关 ----------------------


    // 卖出全部持仓
    function test_sell_all_balance() public {

        deal(USDT, user, 100e18);
        _swap(user, USDT, address(djs), 100e18);

        uint256 bal = djs.balanceOf(user);
        _swap(user, address(djs), USDT, bal);

        assertEq(djs.balanceOf(user), 0);
        assertEq(djs.totalCostUsdt(user), 0);
    }

    // 卖出亏损或平价，不触发盈利税
    function test_sell_no_profit() public {

        deal(USDT, user, 100e18);
        _swap(user, USDT, address(djs), 100e18);

        // 人为降低价格，让 avg > currentPrice
        // 可以模拟直接操纵 LP 或使用一个小量 sell
        _swap(user1, USDT, address(djs), 1e3);

        uint256 bal = djs.balanceOf(user);
        _swap(user, address(djs), USDT, bal);
        console.log("Marketing balance after no-profit sell:", IERC20(USDT).balanceOf(djs.marketing()));
    }

    // 盈利极大，taxAmount 达到边界
    function test_sell_extreme_profit() public {
        

        deal(USDT, user, 1e20);
        _swap(user, USDT, address(djs), 1e20);

        // 再用大量 USDT 拉高价格
        deal(USDT, user1, 1e22);
        _swap(user1, USDT, address(djs), 1e22);

        uint256 bal = djs.balanceOf(user);
        _swap(user, address(djs), USDT, bal);

        console.log("Marketing balance after extreme profit sell:", IERC20(USDT).balanceOf(djs.marketing()));
    }

    // ---------------------- 成本迁移 / 转账 ----------------------

    // 非交易 transfer 全部转出
    function test_transfer_full_balance() public {
        deal(USDT, user, 100e18);
        _swap(user, USDT, address(djs), 100e18);
        uint256 bal = djs.balanceOf(user);

        vm.startPrank(user);
        djs.transfer(user1, bal);
        vm.stopPrank();

        assertEq(djs.balanceOf(user), 0);
        assertEq(djs.totalCostUsdt(user), 0);
        console.log("User1 cost after full transfer:", djs.totalCostUsdt(user1));
    }

    // 非交易 transfer 部分转账
    function test_transfer_partial() public {
        deal(USDT, user, 100e18);
        _swap(user, USDT, address(djs), 100e18);
        uint256 half = djs.balanceOf(user) / 2;

        vm.startPrank(user);
        djs.transfer(user1, half);
        vm.stopPrank();

        console.log("User cost after partial transfer:", djs.totalCostUsdt(user));
        console.log("User1 cost after partial transfer:", djs.totalCostUsdt(user1));
    }




   
}
