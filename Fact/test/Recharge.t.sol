// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test,console} from "forge-std/Test.sol";
import {Fact} from "../src/Fact.sol";
import {Recharge} from "../src/Recharge.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IUniswapV2Router02} from "../src/interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Factory} from "../src/interfaces/IUniswapV2Factory.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract RechargeTest is Test{
    //recharge data
    Recharge public recharge;
    address public admin;
    address public recipient;
    address public sender;
    address public percent100;

    //fact data
    Fact    public fact;
    address public buyFee;
    address public sellFee;
    address public initialRecipient;
    address public openAddr;

    address wbnb;
    address uniswapV2Router;
    address user;

    uint256 mainnetFork;

    function setUp() public {
        mainnetFork = vm.createFork(vm.envString("rpc_url"));
        vm.selectFork(mainnetFork);

        //recharge data init
        admin = address(0x39BD0a3E2c70CeE992B11F5Ca12f10489a53C53D);
        recipient = address(0x02602fDaB8Ad6b0dA6FF9cE21d0bfFA471B2f626);
        sender = address(0x19621484D92031BfcDA0DE53920B25FE514A3c12);
        percent100 = address(0x7b8865D82c21CE764b27718151fF4097e626462C);

        //fact data init 
        buyFee = 0x02602fDaB8Ad6b0dA6FF9cE21d0bfFA471B2f626;
        sellFee = 0xe98a4027Fd01e7A5F181541b4b4b56ed11B2B4C0;
        initialRecipient = 0x3D1f8Da9523f66F7b766b1d3f9502220Db90c181;
        openAddr = 0x717Cc0E17a361c6fe16dB3238255Cda2d79f5a1A;

        //main net
        uniswapV2Router = address(0x10ED43C718714eb63d5aA57B78B54704E256024E);

        user = address(0x1);
        vm.startPrank(initialRecipient);
        //deploy token
        fact = new Fact(initialRecipient, buyFee, sellFee);

        //deploy recharge
        Recharge rechargeImpl = new Recharge();
        ERC1967Proxy rechargeProxy = new ERC1967Proxy(
            address(rechargeImpl),
            abi.encodeCall(rechargeImpl.initialize,(admin, recipient, sender, percent100, address(fact)))
        );
        recharge = Recharge(payable(address(rechargeProxy)));

        fact.setAllowlist(address(recharge), true);
        fact.transferOwnership(initialRecipient);
        vm.stopPrank();

        addLiquidity();
        // console.log("Recharge contract address:",address(recharge));
    }

    function addLiquidity() internal{

        vm.startPrank(initialRecipient);
        uint256 amountBNB = 100e18;
        deal(initialRecipient, amountBNB);
        fact.approve(uniswapV2Router, 10000e18);

        // add liquidity
        IUniswapV2Router02(uniswapV2Router).addLiquidityETH{value:amountBNB}(
            address(fact), 
            10000e18, 
            0, 
            0, 
            initialRecipient, 
            block.timestamp + 10
        );
        
        vm.stopPrank();
    }

    function test_singleRecharge_fact() public {
        vm.startPrank(initialRecipient);
        fact.approve(address(recharge), 1000e18);
        recharge.singleRecharge(address(fact), 1000e18, "test_001");
        vm.stopPrank();

        assertEq(fact.balanceOf(recharge.DEAD()), 700e18);
        assertEq(fact.balanceOf(recharge.donation()), 300e18);
    }

    function test_singleRecharge_BNB() public {
        console.log("Dead balance of fact before recharge:",fact.balanceOf(recharge.DEAD()));
        console.log("Donation balance of fact before recharge:",fact.balanceOf(recharge.donation()));
        vm.startPrank(user);
        uint256 amountBNB = 1e18;
        recharge.singleRecharge{value:amountBNB}(address(0), amountBNB, "test_002");
        vm.stopPrank();
        console.log("Dead balance of fact after recharge:",fact.balanceOf(recharge.DEAD()));
        console.log("Donation balance of fact after recharge:",fact.balanceOf(recharge.donation()));
    }    


}