// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test,console} from "forge-std/Test.sol";
import {X101} from "../src/X101.sol";
import {Deploy} from "../src/Deploy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IUniswapV2Router} from "../src/interfaces/IUniswapV2Router.sol";

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

contract X101Test is Test {
    X101 public x101;

    address sellFee;
    address initialRecipient;

    address user;
    address public adx;
    address public uniswapV2Router;

    uint256 mainnetFork;

    function setUp() public {
        mainnetFork = vm.createFork(vm.envString("rpc_url"));
        vm.selectFork(mainnetFork);

        uniswapV2Router = address(0x1F7CdA03D18834C8328cA259AbE57Bf33c46647c);
        adx = address(0xaF3A1f455D37CC960B359686a016193F72755510);
        sellFee = address(0xd6ccB8aB9351C3656063308ceF9eCE1Dc8C5b3d6);
        
        user = vm.addr(1);
        initialRecipient = vm.addr(2);

        vm.startPrank(initialRecipient);
        Deploy deploy = new Deploy();
        x101 = X101(deploy.deployX101(initialRecipient, sellFee));
        // x101 = new X101(initialRecipient, sellFee);
        deploy.transferOwnership(initialRecipient);
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
        x101.setAllowlist(user, true);
        vm.stopPrank();

        // vm.startPrank(initialRecipient);
        // x101.setAllowlist(addrs, true);
        // vm.stopPrank();
        // assertEq(x101.allowlist(user), true);
    }

    function test_addLiquidity() public {
        vm.startPrank(initialRecipient);
        deal(adx, initialRecipient, 10000e18);
        x101.approve(uniswapV2Router, 10000e18);
        IERC20(adx).approve(uniswapV2Router, 10000e18);

        // add liquidity
        IUniswapV2Router(uniswapV2Router).addLiquidity(
            adx, 
            address(x101), 
            1000e18, 
            1000e18, 
            0, 
            0, 
            initialRecipient, 
            block.timestamp + 10
        );
        vm.stopPrank();
        assertEq(x101.balanceOf(address(x101)), 0);
        assertEq(x101.balanceOf(x101.pancakePair()), 1000e18);
        
    }

    function test_addLiquidity_not_allowlist() public {
        vm.startPrank(initialRecipient);
        x101.transfer(user,1000e18);
        vm.stopPrank();

        vm.startPrank(user);
        deal(adx, user, 1000e18);
        x101.approve(uniswapV2Router, 1000e18);
        IERC20(adx).approve(uniswapV2Router, 1000e18);

        // add liquidity
        IUniswapV2Router(uniswapV2Router).addLiquidity(
            adx, 
            address(x101), 
            1000e18, 
            1000e18, 
            0, 
            0, 
            user, 
            block.timestamp + 10
        );
        vm.stopPrank();

        assertEq(x101.balanceOf(address(x101)), 0);
        assertEq(x101.balanceOf(x101.pancakePair()), 1000e18);
        // assertEq(x101.balanceOf(x101.sellFee()), 200e18);
    }


    function test_removeLiquiditty_not_allowlist() public {
        test_addLiquidity_not_allowlist();
        console.log("X101 balanceof user:",x101.balanceOf(user));
        uint256 lpBalance = IERC20(x101.pancakePair()).balanceOf(user);
        vm.startPrank(user);
        IERC20(x101.pancakePair()).approve(uniswapV2Router, lpBalance);
        //999999999999999999000
        //1000 000000000000000000
        IUniswapV2Router(uniswapV2Router).removeLiquidity(
            address(x101), 
            adx, 
            lpBalance, 
            0, 
            0, 
            user, 
            block.timestamp + 10
        );
        vm.stopPrank();
        // assertEq(x101.balanceOf(user), 999999999999999999000);
    }

    function test_buy() public {
        test_addLiquidity_not_allowlist();
        vm.startPrank(user);
        address[] memory path = new address[](2);
        path[0] = adx;
        path[1] = address(x101);

        deal(adx, user, 50e18);
        IERC20(adx).approve(uniswapV2Router, 50e18);
        vm.expectRevert(bytes("Pancake: TRANSFER_FAILED"));
        IUniswapV2Router(uniswapV2Router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            50e18, 
            0, 
            path, 
            user, 
            block.timestamp
        );
        vm.stopPrank();

    }

    function test_sell() public{
        test_addLiquidity_not_allowlist();

        vm.startPrank(initialRecipient);
        x101.transfer(user, 50e18);
        vm.stopPrank();

        vm.startPrank(user);
        address[] memory path = new address[](2);
        path[0] = address(x101);
        path[1] = adx;
        x101.approve(uniswapV2Router, 50e18);
        IUniswapV2Router(uniswapV2Router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            50e18, 
            0, 
            path, 
            user, 
            block.timestamp
        );
        vm.stopPrank();
        assertEq(x101.balanceOf(x101.sellFee()), 10e18);
    }

    function test_removeLiquidity() public {
        test_addLiquidity();
        
        vm.startPrank(initialRecipient);
        uint256 lpBalance = IERC20(x101.pancakePair()).balanceOf(initialRecipient);
        IERC20(x101.pancakePair()).approve(uniswapV2Router, lpBalance);

        IUniswapV2Router(uniswapV2Router).removeLiquidity(
            address(x101), 
            adx, 
            lpBalance, 
            0, 
            0, 
            initialRecipient, 
            block.timestamp
        );
        vm.stopPrank();
        
    }

    function transfer(address from, address to, uint256 amount) internal{
        vm.startPrank(from);
        x101.transfer(to, amount);
        vm.stopPrank();
    }

    function test_transfer_white_and_nonwhite() public {
        // initialRecipient 已经在白名单，无需额外设置
        address nonWhite = vm.addr(3);

        // ------------------------------
        // 白名单转账（initialRecipient -> user）
        // ------------------------------
        uint256 userBefore = x101.balanceOf(user);
        uint256 sellFeeBefore = x101.balanceOf(x101.sellFee());

        transfer(initialRecipient, user, 100e18);

        uint256 userAfter = x101.balanceOf(user);
        uint256 sellFeeAfter = x101.balanceOf(x101.sellFee());

        // 白名单转账不扣税
        assertEq(userAfter - userBefore, 100e18, "White list: user should receive full amount");
        assertEq(sellFeeAfter - sellFeeBefore, 0, "White list: sellFee should not increase");

        // ------------------------------
        // 非白名单转账（initialRecipient -> nonWhite）
        // ------------------------------
        uint256 nonWhiteBefore = x101.balanceOf(nonWhite);
        sellFeeBefore = x101.balanceOf(x101.sellFee());

        transfer(initialRecipient, nonWhite, 100e18);

        uint256 nonWhiteAfter = x101.balanceOf(nonWhite);
        sellFeeAfter = x101.balanceOf(x101.sellFee());

        // 普通转账不加税（你的 _update 普通转账分支）
        assertEq(nonWhiteAfter - nonWhiteBefore, 100e18, "Non-white: nonWhite should receive full amount");
        assertEq(sellFeeAfter - sellFeeBefore, 0, "Non-white: sellFee should not increase");

        // ------------------------------
        // 非白名单卖出（nonWhite -> pancakePair）触发 SELL_TAX_RATE
        // ------------------------------
        vm.startPrank(nonWhite);
        x101.approve(uniswapV2Router, 100e18);

        // 模拟卖出到 pancakePair（不使用 Router，直接 transfer 更方便测试）
        uint256 pairBefore = x101.balanceOf(x101.pancakePair());
        sellFeeBefore = x101.balanceOf(x101.sellFee());

        transfer(nonWhite, x101.pancakePair(), 100e18);

        uint256 pairAfter = x101.balanceOf(x101.pancakePair());
        sellFeeAfter = x101.balanceOf(x101.sellFee());
        vm.stopPrank();

        uint256 expectedFee = (100e18 * x101.SELL_TAX_RATE()) / 100;
        uint256 expectedReceive = 100e18 - expectedFee;

        assertEq(pairAfter - pairBefore, expectedReceive, "Non-white: pancakePair should receive amount minus fee");
        assertEq(sellFeeAfter - sellFeeBefore, expectedFee, "Non-white: sellFee should receive fee");
        console.log("transfer test running...");

    }

}