// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test,console} from "forge-std/Test.sol";
import {NodeDividends} from "../src/NodeDividends.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TDjs} from "../src/mock/TDjs.sol";
import {TNfts} from "../src/mock/TNfts.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NodeDividendsTest is Test{
    NodeDividends public    nodeDividends;
    TNfts         public    nfts;
    TDjs          public    token;
    address       public    staking;
    address       public    usdt;
    address       public    owner;
    address       public    user;
    uint256       mainnetFork;

    function setUp() public {
        mainnetFork = vm.createFork(vm.envString("rpc_url"));
        vm.selectFork(mainnetFork);

        usdt = address(0x55d398326f99059fF775485246999027B3197955);
        staking = address(1);
        owner = address(2);
        user = address(3);

        vm.startPrank(owner);
        // deploy nfts
        nfts = new TNfts();
        //deploy token
        token = new TDjs();
        //deploy node
        NodeDividends nodeImpl = new NodeDividends();
        ERC1967Proxy nodeProxy = new ERC1967Proxy(
            address(nodeImpl),
            abi.encodeCall(nodeImpl.initialize,(address(nfts), address(token)))
        );
        nodeDividends = NodeDividends(payable(address(nodeProxy)));
        nodeDividends.setStaking(staking);
        deal(usdt, address(nodeDividends), 1000e18);
        vm.stopPrank();
    }

    function test_stake_and_reStake() public {
        vm.startPrank(owner);//setApprovalForAll
        nfts.mint(user);
        nfts.mint(user);
        vm.stopPrank();

        //第一次质押
        vm.startPrank(user);
        IERC721(nfts).setApprovalForAll(address(nodeDividends), true);
        uint256[] memory nftIds = new uint256[](1);
        nftIds[0] = 1;
        nodeDividends.stake(nftIds);
        vm.stopPrank();

        //验证质押信息
        (uint256 nftQuantity,
            uint256[] memory tokenIds,
            uint256 releaseQuota,
            uint256 stakingTime,,,,,,) = nodeDividends.getUserInfo(user);
        assertEq(tokenIds.length, 1);
        assertEq(nftQuantity, 1);
        assertEq(releaseQuota, tokenIds.length * nodeDividends.forexRate());
        assertEq(stakingTime, block.timestamp);

        vm.warp(block.timestamp + 1 days);
        //验证token释放数据
        uint256 release = releaseQuota * 86400 / (30 * 86400);
        // (,,,,,,,,uint256 claimableToken,) = nodeDividends.getUserInfo(user);
        (,uint256 claimableToken) = nodeDividends.getReleaseAmountToken(user);
        assertEq(claimableToken, release);


        //第二次质押
        vm.startPrank(user);
        IERC721(nfts).setApprovalForAll(address(nodeDividends), true);
        uint256[] memory nftIdsTwice = new uint256[](1);
        nftIdsTwice[0] = 2;
        nodeDividends.stake(nftIdsTwice);
        vm.stopPrank();

        (uint256 nftQuantity0,
        uint256[] memory tokenIds0,
        uint256 releaseQuota0,
        uint256 stakingTime0,
        uint256 pendingToken,,,,
        uint256 claimableToken0,) = nodeDividends.getUserInfo(user);

        assertEq(tokenIds0.length, 2);
        assertEq(nftQuantity0, 2);
        assertEq(releaseQuota0, tokenIds0.length * nodeDividends.forexRate());
        assertEq(stakingTime0, block.timestamp);
        assertEq(pendingToken, release);
        assertEq(claimableToken0, release);

    }

    function test_claim() public {
        
    }

    // uint256 nftQuantity,
    //         uint256[] memory tokenIds,
    //         uint256 releaseQuota,
    //         uint256 stakingTime,
    //         uint256 pendingToken,
    //         uint256 pendingUSDT,
    //         uint256 extractedToken,
    //         uint256 farmDebt,
    //         uint256 claimableToken,
    //         uint256 availableUSDT

}
