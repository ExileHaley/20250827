// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// import {Test,console} from "forge-std/Test.sol";
// import {X101} from "../src/X101.sol";
// import {Deploy} from "../src/Deploy.sol";
// import {Recharge} from "../src/Recharge.sol";
// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import {IUniswapV2Router} from "../src/interfaces/IUniswapV2Router.sol";
// // import {IUniswapV2Factory} from "../src/interfaces/IUniswapV2Factory";

// contract X101V2Test is Test {
//     //token param
//     X101 public x101;
//     address sellFee;
//     address initialRecipient;

//     //recharge param
//     Recharge public recharge;
//     address public admin;
//     address public recipient;
//     address public sender;
//     address public percent50;
//     address public percent40;
//     address public percent10;

//     //test param
//     address user;
//     address public adx;
//     address public router;

//     //net param
//     uint256 mainnetFork;

//     function setUp() public {
//         mainnetFork = vm.createFork(vm.envString("rpc_url"));
//         vm.selectFork(mainnetFork);

//         // uniswapV2Router = address(0x1F7CdA03D18834C8328cA259AbE57Bf33c46647c);
//         // adx = address(0xaF3A1f455D37CC960B359686a016193F72755510);
//         // sellFee = address(0xd6ccB8aB9351C3656063308ceF9eCE1Dc8C5b3d6);
        
//         // user = vm.addr(1);
//         // initialRecipient = vm.addr(2);

//         // vm.startPrank(initialRecipient);
//         // Deploy deploy = new Deploy();
//         // x101 = X101(deploy.deployX101(initialRecipient, sellFee));
//         // // x101 = new X101(initialRecipient, sellFee);
//         // deploy.transferOwnership(initialRecipient);
//         vm.stopPrank();
        
//     }
// }