// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Cfun} from "../src/Cfun.sol";
import {Staking} from "../src/Staking.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SignatureInfo} from "../src/libraries/SignatureInfo.sol";

// import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract StakingTest is Test{
    Staking public staking;
    Cfun    public cfun;

    address public initial;

    address public cessToken;
    address public cessRecipient;
    address public admin;
    // address public signer;
    address public owner;

    address user;

    uint256 mainnetFork;
    address SIGNER;
    uint256 SIGNER_PRIVATE_KEY;

    function setUp() public{
        mainnetFork = vm.createFork(vm.envString("rpc_url"));
        vm.selectFork(mainnetFork);
        //参数初始化
        {
            initial = address(1);
            cessToken = address(0x0c78d4605c2972e5f989DE9019De1Fb00c5D3462);
            cessRecipient = address(2);
            admin = address(3);
            SIGNER_PRIVATE_KEY = 4;
            SIGNER = vm.addr(SIGNER_PRIVATE_KEY);
            owner = address(5);
            user = address(6);
        }
        vm.startPrank(owner);
        //合约部署
        //部署代币
        {
            cfun = new Cfun(initial);
        }
        //初始化白名单
        address[] memory addrs = new address[](1);
        addrs[0] = address(7);
        //部署质押合约
        {
            Staking stakingImpl = new Staking();
            ERC1967Proxy stakingProxy = new ERC1967Proxy(
                address(stakingImpl),
                abi.encodeCall(stakingImpl.initialize,(cessToken, address(cfun), cessRecipient, admin, SIGNER, addrs))
            );
            staking = Staking(payable(address(stakingProxy)));
        }
        vm.stopPrank();

        //向合约里转入cfun
        vm.startPrank(initial);
        cfun.transfer(address(staking), 10000e18);
        vm.stopPrank();
    }

    function test_stake() public {
        vm.startPrank(user);
        uint256 amount = 10000e18;
        deal(cessToken, user, amount);
        IERC20(cessToken).approve(address(staking), amount);
        staking.stake(amount);
        vm.stopPrank();

        assertEq(staking.isStaking(user), true);
    }

    function buildSignedMsg(
        string memory mark,
        address token,
        address recipient,
        uint256 amount,
        uint256 fee,
        uint256 deadline
    ) internal view returns (SignatureInfo.SignMessage memory) {
        SignatureInfo.SignMessage memory msgData;
        msgData.mark = mark;
        msgData.token = token;
        msgData.recipient = recipient;
        msgData.amount = amount;
        msgData.fee = fee;
        msgData.nonce = staking.nonce();
        msgData.deadline = deadline;

        // 生成 EIP712 哈希并签名
        bytes32 digest = staking.getSignMsgHash(msgData);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(SIGNER_PRIVATE_KEY, digest);

        msgData.v = v;
        msgData.r = r;
        msgData.s = s;

        return msgData;
    }

    function test_withdrawWithSignature() public {
        // 先 stake
        vm.startPrank(user);
        uint256 amount = 10000e18;
        deal(cessToken, user, amount);
        IERC20(cessToken).approve(address(staking), amount);
        staking.stake(amount);
        vm.stopPrank();

        // 构造签名消息（调用封装函数）
        SignatureInfo.SignMessage memory msgData = buildSignedMsg(
            "tx1",
            address(cfun),
            user,
            100e18,
            1e18,
            block.timestamp + 1 days
        );

        // 提现
        vm.startPrank(user);
        staking.withdrawWithSignature(msgData);
        vm.stopPrank();

        // 验证结果
        assertEq(cfun.balanceOf(user), 100e18, "User should receive tokens");
        assertEq(cfun.balanceOf(cessRecipient), 1e18, "Fee should be sent to recipient");
        assertTrue(staking.isExcuted("tx1"), "Mark should be recorded");
    }

}