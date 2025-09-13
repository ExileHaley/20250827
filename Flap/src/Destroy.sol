// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {TransferHelper} from "./libraries/TransferHelper.sol";
import {ReentrancyGuard} from "./libraries/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Destroy is Initializable, OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuard{

    // --- constants ---
    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;
    uint256 private constant ACC_PRECISION = 1e18;
    uint256 private constant SECONDS_PER_DAY = 86400;


    // --- user data ---
    struct User{
        uint256 stakingAmount; // 用户质押数量
        uint256 pending; 
        uint256 debt; // 奖励债务
    }

    mapping(address => User) public userInfo;


    // --- state ---
    address public flap; // 质押代币
    address public subToken; // 奖励代币
    uint256 public totalDailyOutput; // 每日总产出（例：500e18）


    uint256 public accRewardPerShare; // 累积奖励/每份质押
    uint256 public lastRewardTime; // 上次结算时间
    uint256 public totalStaked; // 总质押量


    // --- events ---
    event FlapDestroyed(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount, uint256 fee);
    event Claimed(address indexed user, uint256 amount);
    event TotalDailyOutputChanged(uint256 oldVal, uint256 newVal);


    // --- init ---
    function initialize(address _flap, address _subToken) public initializer {
        __Ownable_init_unchained(_msgSender());
        __UUPSUpgradeable_init_unchained();    
        flap = _flap;
        subToken = _subToken;
        totalDailyOutput = 500e18;
        lastRewardTime = block.timestamp;
    }

    // Authorize contract upgrades only by the owner
    function _authorizeUpgrade(address newImplementation) internal view override onlyOwner() {}

    function rewardPerSecond() public view returns (uint256) {
        return totalDailyOutput / SECONDS_PER_DAY;
    }

    /// @notice 查看用户可领取（即时累积 + pending）奖励
    function pendingReward(address _user) public view returns (uint256) {
        User storage user = userInfo[_user];
        uint256 _acc = accRewardPerShare;

        if (block.timestamp > lastRewardTime && totalStaked > 0) {
            uint256 elapsed = block.timestamp - lastRewardTime;
            uint256 reward = elapsed * rewardPerSecond();
            _acc += (reward * ACC_PRECISION) / totalStaked;
        }

        uint256 accumulated = (user.stakingAmount * _acc) / ACC_PRECISION;
        // accumulated - user.debt 是自上次 debt 之后新产生的奖励（尚未计入 pending）
        return user.pending + (accumulated - user.debt);
    }

    // --- internal accounting ---
    function _updatePool() internal {
        if (block.timestamp <= lastRewardTime) return;

        if (totalStaked == 0) {
            lastRewardTime = block.timestamp;
            return;
        }

        uint256 elapsed = block.timestamp - lastRewardTime;
        uint256 reward = elapsed * rewardPerSecond();
        accRewardPerShare += (reward * ACC_PRECISION) / totalStaked;
        lastRewardTime = block.timestamp;
    }

    // --- user actions ---
    /// @notice 质押 flap（不会立即发放奖励，只将新产生的奖励累积到 user.pending）
    function destroy(uint256 _amount) external nonReentrant {
        require(_amount > 0, "zero amount");
        User storage user = userInfo[msg.sender];

        _updatePool();

        // 把自上次 debt 之后产生的奖励累积到 pending
        uint256 accumulated = (user.stakingAmount * accRewardPerShare) / ACC_PRECISION;
        uint256 reward = 0;
        if (accumulated > user.debt) {
            reward = accumulated - user.debt;
            user.pending += reward;
        }

        // 转入质押代币
        TransferHelper.safeTransferFrom(flap, msg.sender, DEAD, _amount);

        user.stakingAmount += _amount;
        totalStaked += _amount;

        // 更新 debt 为新的 stakingAmount 对应的 acc
        user.debt = (user.stakingAmount * accRewardPerShare) / ACC_PRECISION;

        emit FlapDestroyed(msg.sender, _amount);
    }

    /// @notice 提取奖励（会将 pending 与当前应得合并并转出）
    function claim() external nonReentrant {
        User storage user = userInfo[msg.sender];

        _updatePool();

        // 合并应得到 pending
        uint256 accumulated = (user.stakingAmount * accRewardPerShare) / ACC_PRECISION;
        if (accumulated > user.debt) {
            user.pending += (accumulated - user.debt);
        }

        user.debt = accumulated;

        uint256 toSend = user.pending;
        require(toSend > 0, "no rewards");

        user.pending = 0;

        TransferHelper.safeTransfer(subToken, msg.sender, toSend);
        emit Claimed(msg.sender, toSend);
    }

    // --- admin ---
    /// @notice 修改每日产出（owner）
    function setTotalDailyOutput(uint256 _new) external onlyOwner {
        emit TotalDailyOutputChanged(totalDailyOutput, _new);
        _updatePool(); // 先把当前产生的奖励结算
        totalDailyOutput = _new;
    }

    function setTokenAddr(address _flap, address _subToken) external onlyOwner{
        flap = _flap;
        subToken = _subToken;
    }

    function emergencyWithdraw() external nonReentrant  onlyOwner{
        uint256 flapAmount = IERC20(flap).balanceOf(address(this));
        uint256 subTokenAmount = IERC20(subToken).balanceOf(address(this));
        if(flapAmount > 0) TransferHelper.safeTransfer(flap, msg.sender, flapAmount);
        if(subTokenAmount > 0) TransferHelper.safeTransfer(subToken, msg.sender, subTokenAmount);
      
    }

}