// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// import {Test, console} from "forge-std/Test.sol";
// import {Demo} from "../src/Demo.sol";
// import {IUniswapV2Router02} from "../src/interfaces/IUniswapV2Router02.sol";
// import {IUniswapV2Factory} from "../src/interfaces/IUniswapV2Factory.sol";
// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// contract DemoTest is Test{
//     Skp public skp;
//     address initialRecipient;
//     address sellFee;

//     address user;
//     address buyBackWallet;
//     address attributableTo;
//     address public USDT;
//     address public uniswapV2Router;

//     uint256 mainnetFork;

//     function setUp() public {
//         mainnetFork = vm.createFork(vm.envString("rpc_url"));
//         vm.selectFork(mainnetFork);

//         uniswapV2Router = address(0x10ED43C718714eb63d5aA57B78B54704E256024E);
//         USDT = address(0x55d398326f99059fF775485246999027B3197955);
//         sellFee = address(0x73832D01364c48e4b6C49B9ECBF07aB92852B67c);
        
//         user = vm.addr(1);
//         initialRecipient = vm.addr(2);
//         attributableTo = vm.addr(4);
//         buyBackWallet = vm.addr(5);

//         vm.startPrank(initialRecipient);
//         skp = new Skp(initialRecipient, sellFee, buyBackWallet, attributableTo);
//         vm.stopPrank();

//         vm.startPrank(buyBackWallet);
//         deal(USDT, buyBackWallet, 1000000000e18);
//         IERC20(USDT).approve(address(skp), 1000000000e18);
//         vm.stopPrank();

//         addLiquidity_allowlist();
//     }

//     function addLiquidity_allowlist() public {
//         vm.startPrank(initialRecipient);
//         deal(USDT, initialRecipient, 10000e18);
//         skp.approve(uniswapV2Router, 10000e18);
//         IERC20(USDT).approve(uniswapV2Router, 10000e18);

//         IUniswapV2Router02(uniswapV2Router).addLiquidity(
//             USDT, 
//             address(skp), 
//             10000e18, 
//             10000e18, 
//             0, 
//             0, 
//             initialRecipient, 
//             block.timestamp + 10
//         );

//         vm.stopPrank();
//         assertEq(skp.balanceOf(skp.pancakePair()), 10000e18);
//     }

//     function test_sell_not_allowlist() public {
//         // test_addLiquidity_allowlist();
//         vm.startPrank(initialRecipient);
//         skp.transfer(user, 101e18);
//         vm.stopPrank();
//         // console.log("usdt balance of sellFee before user sell:",IERC20(USDT).balanceOf(sellFee));
//         vm.startPrank(user);
//         skp.approve(uniswapV2Router, 100e18);
//         address[] memory path = new address[](2);
//         path[0] = address(skp);
//         path[1] = USDT;
//         IUniswapV2Router02(uniswapV2Router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
//             100e18, 
//             0, 
//             path, 
//             user, 
//             block.timestamp + 10
//         );
//         vm.stopPrank();
        
//         console.log("skp balance of attributableTo after user sell:",skp.balanceOf(attributableTo));
//     }

//     function test_transfer_for_feeToUSDT() public {
//         test_sell_not_allowlist();
//         vm.startPrank(user);
//         address user1 = vm.addr(0x3);
//         skp.transfer(user1, 1e18);
//         console.log("usdt balance of sellFee after user sell and transfer:",IERC20(USDT).balanceOf(sellFee));
//         vm.stopPrank();
//     }

// }