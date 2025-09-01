// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {TransferHelper} from "./TransferHelper.sol";
import {ReentrancyGuard} from "./ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Staking is Initializable, OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuard{

    event Stake(uint256 orderId, address holder, uint256 amount, IdentityType identity, uint256 time);
    event Referrer(address inviter, address invitees, uint256 time);
    event Claim(address holder, BonusType bonus, uint256 time);

    enum BonusType{
        INVALID,
        SMALL_AREA_REWARDS,
        REFERRAL_REWARDS
    }

    enum IdentityType {
        INVALID,
        BASIC,   // 900
        ADVANCED, // 2900
        ELITE    // 5900
    }


    struct StakingOrder {
        address holder;
        uint256 cessAmount;
        uint256 stakingTime;
        uint256 withdrawnEarnings; //当前订单已提取收益
        bool    extracted;
    }
    mapping(uint256 => StakingOrder) public stakingOrderInfo;
    mapping(address => uint256[]) public stakingOrdersIds;
    mapping(address => address[]) public directReferrers;
    mapping(address => IdentityType) public identityInfo;

    address public cessToken;
    address public cfunToken;

    address public admin;
    uint256 public nextOrderId;
    //订单收益/动态奖励/小区奖励是否随时提取
    //订单收益的计算方式
    //动态奖励的计算方式
    //小区奖励的计算方式
    receive() external payable{}

    // --- Modifiers ---
    modifier onlyHolder(uint256 orderId) {
        require(stakingOrderInfo[orderId].holder == msg.sender, "not order owner");
        _;
    }

    function initialize(address _cessToken,address _cfunToken, address _admin) public initializer {
        __Ownable_init_unchained(_msgSender());
        __UUPSUpgradeable_init_unchained();
        cessToken = _cessToken;
        cfunToken = _cfunToken;
        admin = _admin;
        nextOrderId = 1;
        //初始化收益单位
    }

     // Authorize contract upgrades only by the owner
    function _authorizeUpgrade(address newImplementation) internal view override onlyOwner(){}

    function addIdentity(address[] calldata addrs, IdentityType identity) external onlyOwner{
        for(uint i=0; i<addrs.length; i++){
            identityInfo[addrs[i]] = identity;
        }
    }
}