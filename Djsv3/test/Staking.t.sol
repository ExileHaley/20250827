// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test,console} from "forge-std/Test.sol";
import {Staking} from "../src/Staking.sol";
import {LiquidityManager} from "../src/LiquidityManager.sol";
import {NodeDividends} from "../src/NodeDividends.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TDjs} from "../src/mock/TDjs.sol";
import {TDjsc} from "../src/mock/TDjsc.sol";
import {IUniswapV2Router02} from "../src/interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Factory} from "../src/interfaces/IUniswapV2Factory.sol";
import {Errors} from "../src/libraries/Errors.sol";
import {Process} from "../src/libraries/Process.sol";
interface IDjsv1 {
    function userInfo(address user) 
        external 
        view 
        returns (
            address recommender, 
            uint256 staking, 
            uint256 performance, 
            uint256 referralNum
        );
    function getUserInfo(address user) 
        external 
        view 
        returns (
            address recommender, 
            uint256 staking, 
            uint256 performance, 
            uint256 referralNum, 
            address[] memory referrals
        );
}

contract StakingTest is Test{
    Staking public staking;
    address public admin;
    address public initialCode;
    address public djsv1;
    NodeDividends public nodeDividends;
    LiquidityManager public liquidityManager;
    TDjs public tdjs;
    TDjsc public tdjsc;


    address public USDT;
    address public uniswapV2Router;
    uint256 mainnetFork;
    address public owner;
    address public user;
    address user1 = address(1001);
    address user2 = address(1002);
    function setUp() public {
        mainnetFork = vm.createFork(vm.envString("rpc_url"));
        vm.selectFork(mainnetFork);
        //mainnet address
        uniswapV2Router = address(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        USDT = address(0x55d398326f99059fF775485246999027B3197955);
        djsv1 = address(0x0e7f2f2155199E2606Ce24C9b2C5C7C3D5960116);


        admin = address(1);
        initialCode = address(2);
        owner = address(3);
        user = address(4);
        user1 = address(1001);
        user2 = address(1002);

        vm.startPrank(owner);
        tdjs = new TDjs();
        tdjsc = new TDjsc();

        //deply liquidity manager
        LiquidityManager liquidityImpl = new LiquidityManager();
        ERC1967Proxy liquidityProxy = new ERC1967Proxy(
            address(liquidityImpl),
            abi.encodeCall(liquidityImpl.initialize,(address(tdjs), address(tdjsc)))
        );
        liquidityManager = LiquidityManager(payable(address(liquidityProxy)));

        //deply node 
        NodeDividends nodeImpl = new NodeDividends();
        ERC1967Proxy nodeProxy = new ERC1967Proxy(
            address(nodeImpl),
            abi.encodeCall(nodeImpl.initialize,())
        );
        nodeDividends = NodeDividends(payable(address(nodeProxy)));

        //deploy staking
        Staking stakingImpl = new Staking();
        ERC1967Proxy stakingProxy = new ERC1967Proxy(
            address(stakingImpl),
            abi.encodeCall(stakingImpl.initialize,(admin, initialCode, djsv1, address(nodeDividends), address(liquidityManager)))
        );
        staking = Staking(payable(address(stakingProxy)));

        liquidityManager.setStaking(address(staking));
        nodeDividends.setStaking(address(staking));
        addLiquidity(address(tdjs));
        addLiquidity(address(tdjsc));

        vm.stopPrank();

    }

    function addLiquidity(address token) internal{
        // vm.startPrank(owner);
        uint256 amountUSDT = 10000e18;
        deal(USDT, owner, amountUSDT);
        IERC20(USDT).approve(uniswapV2Router, amountUSDT);
        IERC20(token).approve(uniswapV2Router, 10000e18);
        IUniswapV2Router02(uniswapV2Router).addLiquidity(
            USDT, 
            token, 
            10000e18, 
            10000e18, 
            0, 
            0, 
            msg.sender, 
            block.timestamp + 10
        );
        // vm.stopPrank();
    }

    function test_referral() public {
        vm.startPrank(user);
    
        vm.expectRevert(Errors.InvalidRecommender.selector);
        staking.referral(user);

        vm.expectRevert(Errors.ZeroAddress.selector);
        staking.referral(address(0));

        staking.referral(initialCode);

        vm.expectRevert(Errors.InviterExists.selector);
        staking.referral(initialCode);

        vm.stopPrank();
    }

    function test_stake() public {
        vm.startPrank(user);
        staking.referral(initialCode);
        uint256 amountUSDT = 100e18;
        deal(USDT, user, amountUSDT);
        IERC20(USDT).approve(address(staking), amountUSDT);
        staking.stake(amountUSDT);

        //数据验证
        (uint256 referralNum,
        uint256 performance,
        uint256 referralAward,
        uint256 subCoinQuota,
        bool    isMigration )= staking.getUserInfoReferral(initialCode);
        assertEq(referralNum, 1);
        console.log("initialCode referralNum:",referralNum);
        assertEq(performance, amountUSDT);
        assertEq(referralAward, amountUSDT * 50 / 100);
        assertEq(subCoinQuota, 0);
        assertEq(isMigration, false);
        Process.Record[] memory records = staking.getReferralAwardRecords(initialCode);
        console.log("records length:",records.length);
        vm.stopPrank();
    }

    function test_upgradeLevelV1() public {
        
        address user3 = address(1003);

        // 给每个用户分配 USDT
        deal(USDT, user1, 4000e18);
        deal(USDT, user2, 3000e18);
        deal(USDT, user3, 4000e18);

        // user1 操作
        vm.startPrank(user1);
        staking.referral(initialCode);
        IERC20(USDT).approve(address(staking), 4000e18);
        staking.stake(4000e18);
        vm.stopPrank();

        // user2 操作
        vm.startPrank(user2);
        staking.referral(initialCode);
        IERC20(USDT).approve(address(staking), 3000e18);
        staking.stake(3000e18);
        vm.stopPrank();

        // user3 操作
        vm.startPrank(user3);
        staking.referral(initialCode);
        IERC20(USDT).approve(address(staking), 4000e18);
        staking.stake(4000e18);
        vm.stopPrank();

        // 断言 initialCode 已升级到 V1
        (Process.Level level,,,,,) = staking.getUserInfoBasic(initialCode);
        assertEq(uint256(level), uint256(Process.Level.V1));

        (uint256 referralNum,uint256 performance,,,) = staking.getUserInfoReferral(initialCode);
        assertEq(referralNum, 3);
        assertEq(performance, 11000e18); // 4000 + 3000 + 4000
        // assertEq(referralAward, 0);
        // assertEq(subCoinQuota, 100e18);

        // console.log("referralNum:",referralNum);
        // console.log("performance:",performance);
        // console.log("level:",uint256(level));
    }

    function test_upgradeLevelV2() public {
        test_upgradeLevelV1();
        // 假设 initialCode 已经升级到 V1，已有3个下级用户 user1, user2, user3
        address user4 = address(1004);

        // 给 user4 分配 USDT
        deal(USDT, user4, 40000e18); // 11000 + 40000 = 51000 ≥ 50000

        // user4 绑定 initialCode 并质押
        vm.startPrank(user4);
        staking.referral(initialCode);
        IERC20(USDT).approve(address(staking), 40000e18);
        staking.stake(40000e18);
        vm.stopPrank();

        // 检查 initialCode 是否升级到 V2
        (Process.Level level,,,,,) = staking.getUserInfoBasic(initialCode);
        assertEq(uint256(level), uint256(Process.Level.V2));

        (uint256 referralNum, uint256 performance,,,) = staking.getUserInfoReferral(initialCode);
        assertEq(referralNum, 4);
        assertEq(performance, 11000e18 + 40000e18); // 总 performance = 51000e18
    }

    function test_upgradeLevelV3() public {
        // 先升级到 V2
        test_upgradeLevelV2();

        // 添加第 5 个用户
        address user5 = address(1005);

        // 给 user5 分配 USDT
        uint256 user5Amount = 149000e18; // 51000 + 149000 = 200000
        deal(USDT, user5, user5Amount);

        // user5 绑定 initialCode 并质押
        vm.startPrank(user5);
        staking.referral(initialCode);
        IERC20(USDT).approve(address(staking), user5Amount);
        staking.stake(user5Amount);
        vm.stopPrank();

        // 检查 initialCode 是否升级到 V3
        (Process.Level level,,,,,) = staking.getUserInfoBasic(initialCode);
        assertEq(uint256(level), uint256(Process.Level.V3));

        (uint256 referralNum, uint256 performance,,,) = staking.getUserInfoReferral(initialCode);
        assertEq(referralNum, 5);
        assertEq(performance, 51000e18 + user5Amount); // 总 performance = 200000e18
    }

    function test_upgradeLevelV4() public {
        // 先升级到 V3
        test_upgradeLevelV3();

        // 添加第 6、7 个用户
        address user6 = address(1006);
        address user7 = address(1007);

        // 给用户分配 USDT，使 performance 达到 800000
        uint256 user6Amount = 300000e18; // performance: 200000 + 300000 = 500000
        uint256 user7Amount = 300000e18; // performance: 500000 + 300000 = 800000
        deal(USDT, user6, user6Amount);
        deal(USDT, user7, user7Amount);

        // user6 质押
        vm.startPrank(user6);
        staking.referral(initialCode);
        IERC20(USDT).approve(address(staking), user6Amount);
        staking.stake(user6Amount);
        vm.stopPrank();

        // user7 质押
        vm.startPrank(user7);
        staking.referral(initialCode);
        IERC20(USDT).approve(address(staking), user7Amount);
        staking.stake(user7Amount);
        vm.stopPrank();

        // 检查 initialCode 是否升级到 V4
        (Process.Level level,,,,,) = staking.getUserInfoBasic(initialCode);
        assertEq(uint256(level), uint256(Process.Level.V4));

        (uint256 referralNum, uint256 performance,,,) = staking.getUserInfoReferral(initialCode);
        assertEq(referralNum, 7);
        assertEq(performance, 800000e18);
    }

    function test_upgradeLevelV5() public {
        // 先升级到 V4
        test_upgradeLevelV4();

        // 添加第 8、9 个用户
        address user8 = address(1008);
        address user9 = address(1009);

        // 给用户分配 USDT，使 performance 达到 3000000
        uint256 user8Amount = 1100000e18; // performance: 800000 + 1100000 = 1900000
        uint256 user9Amount = 1100000e18; // performance: 1900000 + 1100000 = 3000000
        deal(USDT, user8, user8Amount);
        deal(USDT, user9, user9Amount);

        // user8 质押
        vm.startPrank(user8);
        staking.referral(initialCode);
        IERC20(USDT).approve(address(staking), user8Amount);
        staking.stake(user8Amount);
        vm.stopPrank();

        // user9 质押
        vm.startPrank(user9);
        staking.referral(initialCode);
        IERC20(USDT).approve(address(staking), user9Amount);
        staking.stake(user9Amount);
        vm.stopPrank();

        // 检查 initialCode 是否升级到 V5
        (Process.Level level,,,,,) = staking.getUserInfoBasic(initialCode);
        assertEq(uint256(level), uint256(Process.Level.V5));

        (uint256 referralNum, uint256 performance,,,) = staking.getUserInfoReferral(initialCode);
        assertEq(referralNum, 9);
        assertEq(performance, 3000000e18);
    }

    function forceUpgradeToV5(address root) internal {
        // 升级到 V1
        upgradeUser(root, 3, 4000e18);     // referralNum = 3, performance = 11000

        // 升级到 V2
        upgradeUser(root, 1, 40000e18);    // performance = 51000

        // 升级到 V3
        upgradeUser(root, 1, 149000e18);   // performance = 200000

        // 升级到 V4
        upgradeUser(root, 2, 300000e18);   // performance = 800000

        // 升级到 V5
        upgradeUser(root, 2, 1100000e18);  // performance = 3000000
        (Process.Level level,,,,,) = staking.getUserInfoBasic(root);
        assertEq(uint256(level), uint256(Process.Level.V5));
        console.log("forceUpgradeToV5 root result:",uint256(level));
    }

    function upgradeUser(address root, uint256 count, uint256 amount) internal {
        for (uint256 i = 0; i < count; i++) {
            address u = address(uint160(uint(keccak256(abi.encode(root, i, amount)))));
            deal(USDT, u, amount);

            vm.startPrank(u);
            staking.referral(root);
            IERC20(USDT).approve(address(staking), amount);
            staking.stake(amount);
            vm.stopPrank();
        }
    }

    function test_upgradeLevelSHARE() public {
        // 先让 initialCode 升级到 V5
        test_upgradeLevelV5();
        // address[] memory dirs = staking.getDirectReferrals(initialCode);
        // assertEq(dirs[0], user1);
        // assertEq(dirs[1], user2);
        // for(uint i=0; i<dirs.length; i++){
        //     assertEq(dirs[0], user1);
        //     console.log(dirs[i]);
        // }
        // 让 user1 完整升级到 V5
        forceUpgradeToV5(user1);

        // 让 user2 完整升级到 V5
        forceUpgradeToV5(user2);

        address[] memory dirs = staking.getDirectReferrals(initialCode);
        console.log("direct referrals after count:", dirs.length);

        uint256 directV5Count = 0;
        for (uint i = 0; i < dirs.length; i++) {
            (Process.Level lv,,,,,) = staking.getUserInfoBasic(dirs[i]);
            // console.log("dir idx:", i, "addr:", dirs[i], "level:", uint256(lv));
            console.log("dir idx:", i);                     // idx
            console.log("addr:", dirs[i]);                  // address
            console.log("level:", uint256(lv));            // level

            if (uint256(lv) == uint256(Process.Level.V5)) directV5Count++;
        }
        console.log("directV5Count:", directV5Count);

        (Process.Level finalLv,,,,,) = staking.getUserInfoBasic(initialCode);
        console.log("initialCode final level:", uint256(finalLv));
        assertGe(directV5Count, 2); // 保证直推 V5 个数达到 2
        assertEq(uint256(finalLv), uint256(Process.Level.SHARE));

        // 检查 initialCode 是否升级到 SHARE
        // (Process.Level level,,,,,) = staking.getUserInfoBasic(initialCode);
        // assertEq(uint256(level), uint256(Process.Level.SHARE));
    }

    function test_user1_upgradeV1_withReferralReward() public {
        // address user1 = address(1001);
        // address user2 = address(1002);
        address user3 = address(1003);
        address user4 = address(1004);
        address user5 = address(1005);

        // 分配 USDT
        deal(USDT, user1, 100e18);
        deal(USDT, user2, 4000e18);
        deal(USDT, user3, 3000e18);
        deal(USDT, user4, 4000e18);
        deal(USDT, user5, 100e18);

        // user1 绑定 initialCode 并质押 100 USDT
        vm.startPrank(user1);
        staking.referral(initialCode);
        IERC20(USDT).approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        // 下级绑定 user1 并质押，触发 user1 升级到 V1
        vm.startPrank(user2);
        staking.referral(user1);
        IERC20(USDT).approve(address(staking), 4000e18);
        staking.stake(4000e18);
        vm.stopPrank();

        vm.startPrank(user3);
        staking.referral(user1);
        IERC20(USDT).approve(address(staking), 3000e18);
        staking.stake(3000e18);
        vm.stopPrank();

        vm.startPrank(user4);
        staking.referral(user1);
        IERC20(USDT).approve(address(staking), 4000e18);
        staking.stake(4000e18);
        vm.stopPrank();

        // 断言 user1 已升级到 V1
        (Process.Level level,,,,,) = staking.getUserInfoBasic(user1);
        assertEq(uint256(level), uint256(Process.Level.V1));
        
        vm.startPrank(user5);
        staking.referral(user1);
        IERC20(USDT).approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();
        // 验证 user1 的邀请奖励（V1 10%）
        (, , uint256 referralAward, uint256 subCoinQuota , ) = staking.getUserInfoReferral(user1);
        uint256 expectedUser1 = 100e18 * 10 / 100; // 下级累计业绩 11000e18 * 10%
        assertEq(referralAward, expectedUser1, "user1 V1 referral reward mismatch");
        assertEq(subCoinQuota, 100e18);
        (,uint256 performance, uint256 referralAwardInitialCode, , ) = staking.getUserInfoReferral(initialCode);
        uint256 expectedInitialCode = 5590e18; // 下级累计业绩 11000e18 * 10%
        assertEq(referralAwardInitialCode, expectedInitialCode, "initialCode referral reward mismatch");
        assertEq(performance, 11200e18);

    }   
    
    //测试购买子币
    function test_swapSubToken() public {
        test_user1_upgradeV1_withReferralReward();
        (Process.Level level,,,,,) = staking.getUserInfoBasic(user1);
        (, , , uint256 subCoinQuota , ) = staking.getUserInfoReferral(user1);
        assertEq(uint256(level), uint256(Process.Level.V1));
        assertEq(subCoinQuota, 100e18);

        vm.startPrank(user1);
        deal(USDT, user1, 100e18);
        IERC20(USDT).approve(address(staking), 100e18);
        staking.swapSubToken(100e18);
        vm.stopPrank();
        (, , , uint256 subCoinQuota0 , ) = staking.getUserInfoReferral(user1);
        assertEq(subCoinQuota0, 0);
        console.log("Sub token balance of User1:",tdjsc.balanceOf(user1));
    }

    
    //测试用户质押收益
    function test_getUserStakeAward() public {
        address user3 = address(1111);
        uint256 amountUsdt = 100e18;
        deal(USDT, user3, amountUsdt);
        vm.startPrank(user3);
        staking.referral(initialCode);
        IERC20(USDT).approve(address(staking), amountUsdt);
        staking.stake(amountUsdt);
        vm.stopPrank();
        vm.warp(block.timestamp + 1 days);
        uint256 stakeAward = staking.getUserStakingAward(user3);
        console.log("One days award:",stakeAward);
        

        vm.warp(block.timestamp + 167 days);
        uint256 userAward = staking.getUserAward(user3);
        console.log("Max award:",userAward);

        address factory = IUniswapV2Router02(uniswapV2Router).factory();
        address pair = IUniswapV2Factory(factory).getPair(USDT, address(tdjs));

        console.log("Before claim token balance of liquidity:",tdjs.balanceOf(address(liquidityManager)));
        console.log("Before claim USDT balance of liquidity:",IERC20(USDT).balanceOf(address(liquidityManager)));
        console.log("Before claim USDT balance of user:",IERC20(USDT).balanceOf(user3));
        console.log("Before claim lp balance of liquidity:",IERC20(pair).balanceOf(address(liquidityManager)));
        
        console.log("100eUSDT require XXXX LP:",liquidityManager.getNeedLP(100e18));
        (uint256 tokenAmount, uint256 usdtAmount) = liquidityManager.quoteLPValue(pair);
        console.log("LP tokenAmount value:",tokenAmount);
        console.log("LP usdtAmount value:",usdtAmount);
        

        vm.startPrank(user3);
        staking.claim(50e18);
        vm.stopPrank();
        assertEq(IERC20(USDT).balanceOf(user3), 45e18);
        (,,,,uint256 extracted) = staking.userInfo(user3);
        assertEq(extracted, 50e18);
        console.log("After claim token balance of liquidity:",tdjs.balanceOf(address(liquidityManager)));
        console.log("After claim USDT balance of liquidity:",IERC20(USDT).balanceOf(address(liquidityManager)));
        console.log("After claim USDT balance of user:",IERC20(USDT).balanceOf(user3));
        console.log("Before claim lp balance of liquidity:",IERC20(pair).balanceOf(address(liquidityManager)));
        assertEq(staking.getUserAward(user3), 150e18);
    }

    // /// @notice 批量生成用户地址（pseudo-random deterministic）
    // function createUsers(address root, uint256 count, uint256 startIndex) pure internal returns (address[] memory users) {
    //     users = new address[](count);
    //     for (uint256 i = 0; i < count; i++) {
    //         // 使用 keccak256 生成一个“确定性”地址
    //         address userx = address(uint160(uint256(keccak256(abi.encode(root, startIndex + i)))));
    //         users[i] = userx;
    //     }
    // }

    // function test_loop_max() public{
    //     address[] memory users = createUsers(user, 1000, 1150);
    //     for(uint i=0; i<users.length; i++){
    //         deal(USDT, users[i], 100e18);
    //         vm.startPrank(users[i]);
    //         IERC20(USDT).approve(address(staking),100e18);
    //         if(i==0) staking.referral(initialCode);
    //         else staking.referral(users[i-1]);
    //         staking.stake(100e18);
    //         vm.stopPrank();
    //     }
    // }

    function test_reStake() public {
        address user3 = address(1111);
        uint256 amountUsdt = 1000e18;
        deal(USDT, user3, amountUsdt);
        vm.startPrank(user3);
        staking.referral(initialCode);
        IERC20(USDT).approve(address(staking), amountUsdt);
        staking.stake(500e18);
        vm.warp(block.timestamp + 1 days);
        uint256 awardOnce = staking.getUserAward(user3);

        staking.stake(500e18);
        (,,,uint256 pendingProfit,) = staking.userInfo(user3);
        assertEq(pendingProfit, awardOnce);
        
        staking.claim(55e17);
        (,,,,uint256 extracted) = staking.userInfo(user3);
        assertEq(extracted, 55e17);
        vm.warp(block.timestamp + 200 days);
        assertEq(staking.getUserAward(user3), 19945e17);
        vm.stopPrank();


    }
   

    //测试节点SHARE收益
    function test_getShareAward() public {}
}

