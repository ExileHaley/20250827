// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test,console} from "forge-std/Test.sol";
import {Recharge} from "../src/Recharge.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVenus {
    function mint(uint mintAmount) external returns (uint);
    function redeem(uint redeemTokens) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
}

contract RechargeTest is Test{
    Recharge public recharge;
    address  public recipient;
    address  public initialCode;
    address  public owner;

    address public user1;
    address public user2;
    address public user3;
    address public user4;

    address public USDT = 0x55d398326f99059fF775485246999027B3197955;
    address public VENUS = 0xfD5840Cd36d94D7229439859C0112a4185BC0255;

    uint256 mainnetFork;
    function setUp() public {
        mainnetFork = vm.createFork(vm.envString("rpc_url"));
        vm.selectFork(mainnetFork);

        
        
        user1 = address(1);
        user2 = address(2);
        user3 = address(3);
        user4 = address(4);

        recipient = address(5);
        initialCode = address(6);
        owner = address(7);

        vm.startPrank(owner);

        Recharge rechargeImpl = new Recharge();
        ERC1967Proxy rechargeProxy = new ERC1967Proxy(
            address(rechargeImpl),
            abi.encodeCall(rechargeImpl.initialize,(recipient, initialCode))
        );
        recharge = Recharge(payable(address(rechargeProxy)));

        vm.stopPrank();
    }

    function test_referral() public {
        // ---------- 正确绑定 initialCode ----------
        vm.startPrank(user1);
        recharge.referral(initialCode);
        vm.stopPrank();

        (address recommender,, , , ) = recharge.getUserInfo(user1);
        assertEq(recommender, initialCode);

        // ---------- 错误情况测试 ----------

        // 1. 推荐自己
        vm.startPrank(user2);
        vm.expectRevert(bytes("INVALID_RECOMMENDER."));
        recharge.referral(user2);
        vm.stopPrank();

        // 2. 推荐地址为 0
        vm.startPrank(user2);
        vm.expectRevert(bytes("ZERO_ADDRESS."));
        recharge.referral(address(0));
        vm.stopPrank();

        // 3. 推荐者不是 initialCode 且没有上级
        // user3 没有绑定过 recommender
        vm.startPrank(user2);
        vm.expectRevert(bytes("RECOMMENDATION_IS_REQUIRED_REFERRAL."));
        recharge.referral(user3);
        vm.stopPrank();

        // 4. 用户已经绑定过 recommender
        vm.startPrank(user1);
        vm.expectRevert(bytes("INVITER_ALREADY_EXISTS."));
        recharge.referral(initialCode);
        vm.stopPrank();
    }


    function test_singleRecharge() public {
        vm.startPrank(user1);
        deal(USDT, user1, 500e18);
        IERC20(USDT).approve(address(recharge), 500e18);
        vm.expectRevert(bytes("RECOMMENDATION_IS_REQUIRED_RECHARGE."));
        recharge.singleRecharge();

        recharge.referral(initialCode);
        recharge.singleRecharge();
        console.log("Venus balance of recipient:",IERC20(VENUS).balanceOf(recipient));
        vm.stopPrank();
        

        vm.startPrank(recipient);
        uint256 venusBalance = IERC20(VENUS).balanceOf(recipient);
        IERC20(VENUS).approve(VENUS, venusBalance);
        IVenus(VENUS).redeem(venusBalance);
        console.log("Usdt balance of recipient:",IERC20(USDT).balanceOf(recipient));
        vm.stopPrank();

    }

    function test_referralNum() public {
        // 用户1 绑定 initialCode
        vm.startPrank(user1);
        recharge.referral(initialCode);
        vm.stopPrank();

        // 用户2 绑定 user1
        vm.startPrank(user2);
        recharge.referral(user1);
        vm.stopPrank();

        // 用户3 绑定 user2
        vm.startPrank(user3);
        recharge.referral(user2);
        vm.stopPrank();

        // 检查 referralNum
        (, , , uint256 refNum1, ) = recharge.getUserInfo(user1);
        (, , , uint256 refNum2, ) = recharge.getUserInfo(user2);
        (, , , uint256 refNum3, ) = recharge.getUserInfo(user3);

        // user1: 被 user2 和 user3 累计推荐
        assertEq(refNum1, 2);
        // user2: 被 user3 推荐
        assertEq(refNum2, 1);
        // user3: 没有下级
        assertEq(refNum3, 0);

        // 检查 directReferrals
        address[] memory dRefs1 = recharge.getDirectReferrals(user1);
        address[] memory dRefs2 = recharge.getDirectReferrals(user2);

        assertEq(dRefs1.length, 1);
        assertEq(dRefs1[0], user2);

        assertEq(dRefs2.length, 1);
        assertEq(dRefs2[0], user3);
    }


    function test_referralPerformance() public {
        // ---------- 用户充值并绑定 ----------
        // user1 绑定 initialCode 并充值
        vm.startPrank(user1);
        deal(USDT, user1, 500e18);
        recharge.referral(initialCode);
        IERC20(USDT).approve(address(recharge), 500e18);
        recharge.singleRecharge(); // 500e18
        vm.stopPrank();

        // user2 绑定 user1 并充值
        vm.startPrank(user2);
        deal(USDT, user2, 500e18);
        recharge.referral(user1);
        IERC20(USDT).approve(address(recharge), 500e18);
        recharge.singleRecharge(); // 500e18
        vm.stopPrank();

        // user3 绑定 user2 并充值
        vm.startPrank(user3);
        deal(USDT, user3, 500e18);
        recharge.referral(user2);
        IERC20(USDT).approve(address(recharge), 500e18);
        recharge.singleRecharge(); // 500e18
        vm.stopPrank();

        // ---------- 检查 performance ----------
        (, , uint256 perf1, , ) = recharge.getUserInfo(user1);
        (, , uint256 perf2, , ) = recharge.getUserInfo(user2);
        (, , uint256 perf3, , ) = recharge.getUserInfo(user3);

        // user1: 下级充值累积 → user2 + user3 = 500 + 500 = 1000e18
        assertEq(perf1, 1000e18);

        // user2: 下级充值累积 → user3 = 500e18
        assertEq(perf2, 500e18);

        // user3: 没有下级充值 → 0
        assertEq(perf3, 0);
    }

}
