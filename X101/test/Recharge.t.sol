// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test,console} from "forge-std/Test.sol";
import {X101} from "../src/X101.sol";
import {Recharge} from "../src/Recharge.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
// import {IUniswapV2Router} from "../src/interfaces/IUniswapV2Router.sol";
// import {IUniswapV2Factory} from "../src/interfaces/IUniswapV2Factory";

contract X101V2Test is Test {
    //token param
    // X101 public x101;
    address public x101;
    address public adx;

    //recharge param
    Recharge public recharge;
    address public admin;
    address public recipient;
    address public sender;
    address public percent50;
    address public percent40;
    address public percent10;

    //test param
    address user;
    address tokenOwner;
    address rechargeOwner;


    //net param
    uint256 mainnetFork;

    function setUp() public {
        mainnetFork = vm.createFork(vm.envString("rpc_url"));
        vm.selectFork(mainnetFork);

        adx = address(0xaF3A1f455D37CC960B359686a016193F72755510);
        x101 = address(0xCC37e50de109483EEdd2dF40557365e3A0D11b62);
        

        admin = 0x6F1fd46936b26C7685670Ec16eF403ec9B826aF9;
        recipient = 0x6cE2aeBDC5Bd15EA1fbA0e234d1147433400d4d4;
        sender = 0xF0E57eCc4a4B0FE0Cb3dd724edcE2e3122bddEE1;
        percent50 = 0xD2d0D05Ae9B339ACBbcD95E3A7210C394102f516;
        percent40 = 0x01cA5237D73D530F67c1413B4884b1A9C49D4aAb;
        percent10 = 0xF10E3cD6e824A1C169a7F6465Fd2221050154BA4;

        user = vm.addr(0x1);
        tokenOwner = address(0x3862120B1570c5D0285d15c9E0A6a38DdCf6569A);
        rechargeOwner = vm.addr(0x2);

        vm.startPrank(rechargeOwner);
        Recharge rechargeImpl = new Recharge();
        ERC1967Proxy rechargeProxy = new ERC1967Proxy(
            address(rechargeImpl),
            abi.encodeCall(rechargeImpl.initialize,(admin, recipient, sender, percent50, percent40, percent10, address(x101)))
        );
        recharge = Recharge(payable(address(rechargeProxy)));
        vm.stopPrank();

        vm.startPrank(tokenOwner);
        X101(x101).setAllowlist(address(recharge), true);
        vm.stopPrank();
        assertEq(X101(x101).allowlist(address(recharge)), true);   
    }

    function test_singleRecharge() public {
        vm.startPrank(user);
        deal(adx, user, 1e18);
        IERC20(adx).approve(address(recharge), 1e18);
        recharge.singleRecharge(adx, 1e18, "test01");
        vm.stopPrank();
    }
}