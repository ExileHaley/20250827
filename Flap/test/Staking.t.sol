// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test,console} from "forge-std/Test.sol";
import {Staking} from "../src/Staking.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract StakingTest is Test {
    Staking public staking;

    address flapToken;
    address subToken;

    address  owner;
    address  user;

    uint256 mainnetFork;

    function setUp() public{
        mainnetFork = vm.createFork(vm.envString("rpc_url"));
        vm.selectFork(mainnetFork);
        //参数初始化
        {
            flapToken = address(0xFE48dFE764e9E9bBeB8C84D70fe710013C681111);
            subToken = address(0xFE48dFE764e9E9bBeB8C84D70fe710013C681111);
            owner = address(1);
            user = address(2);
        }
        vm.startPrank(owner);
        //部署质押合约
        {
            Staking stakingImpl = new Staking();
            ERC1967Proxy stakingProxy = new ERC1967Proxy(
                address(stakingImpl),
                abi.encodeCall(stakingImpl.initialize,(flapToken, subToken))
            );
            staking = Staking(payable(address(stakingProxy)));
        }
        vm.stopPrank();

    }

    function test_stakeAndPending() public {
        deal(flapToken, user, 1000e18);
        vm.startPrank(user);
        IERC20(flapToken).approve(address(staking), 1000e18);

        // 第一次质押 500
        staking.stake(500e18);
        (uint256 stakingAmount, uint256 pending, uint256 debt) = staking.userInfo(user);
        assertEq(stakingAmount, 500e18);
        assertEq(pending, 0);
        assertEq(debt, 0);

        // 快进一天
        vm.warp(block.timestamp + 1 days);

        // 第二次质押 500
        staking.stake(500e18);
        (stakingAmount, pending, debt) = staking.userInfo(user);
        assertEq(stakingAmount, 1000e18);

        // pending 应该累积第一次 500 的奖励
        uint256 acc = staking.accRewardPerShare();
        uint256 expectedPending = (500e18 * acc) / 1e18;
        assertEq(pending, expectedPending);

        // pendingReward 应该 = pending，因为此时刚 stake 完
        uint256 pr = staking.pendingReward(user);
        assertEq(pr, pending);

        vm.stopPrank();
    }

    function test_claimReward() public {
        test_stakeAndPending();

        vm.startPrank(user);

        // claim
        staking.claim();
        (, uint256 pendingAfterClaim, ) = staking.userInfo(user);
        assertEq(pendingAfterClaim, 0);

        // 快进三天，pendingReward 应该增加
        vm.warp(block.timestamp + 3 days);
        uint256 newPending = staking.pendingReward(user);
        assertGt(newPending, 0);

        vm.stopPrank();
    }

    
    function test_pendingIncreaseOnSecondStake() public {
        // 给用户发代币
        deal(flapToken, user, 1000e18);
        deal(flapToken, address(staking), 10000e18);
        vm.startPrank(user);
        IERC20(flapToken).approve(address(staking), 1000e18);

        // 第一次质押 500
        staking.stake(500e18);

        // 快进 3 天，让 accRewardPerShare 足够大
        vm.warp(block.timestamp + 1 days);

        // 第二次质押 500，此时 accumulated > debt，pending 增加
        staking.stake(500e18);
        //此时负债应该是1000，pending应该接近500
        vm.warp(block.timestamp + 3 days);
        //然后我们快进3天，负债依旧是1000，pending这个时候应该是1500，满足了提取收益大于debt
        (uint256 stakingAmount, uint256 pending, uint256 debt) = staking.userInfo(user);
        // 断言
        assertEq(stakingAmount, 1000e18);
        // assertGt(pending, 0);   // pending 应该大于 0
        // assertGt(debt, 0);      // debt 更新
        console.log("pending:",pending);
        console.log("debt:",debt);
        console.log("reward:",staking.pendingReward(user));

        staking.claim();

        (uint256 stakingAmount0, uint256 pending0, uint256 debt0) = staking.userInfo(user);
        // 断言
        assertEq(stakingAmount0, 1000e18);
        // assertGt(pending, 0);   // pending 应该大于 0
        // assertGt(debt, 0);      // debt 更新
        console.log("pending0:",pending0);
        console.log("debt0:",debt0);
        console.log("reward0:",staking.pendingReward(user));

        vm.stopPrank();
    }

}

