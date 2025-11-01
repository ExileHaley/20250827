// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {TransferHelper} from "./libraries/TransferHelper.sol";
import {ReentrancyGuard} from "./libraries/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Subscribe
 * @notice 用户通过 USDT 认购不同等级节点
 *         支持 4 个等级: MICRO / BASIC / MIDDLE / ADVANCED
 *         升级结构 + 分页查询 + 可灵活调整等级金额
 */
contract SubscribeV2 is Initializable, OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuard {

    address public constant USDT = 0x55d398326f99059fF775485246999027B3197955; 
    address public recipient;

    enum Level {
        INVALID,   // 0
        MICRO,     // 1
        BASIC,     // 2
        MIDDLE,    // 3
        ADVANCED   // 4
    }

    /// @notice 各等级对应认购金额
    mapping(Level => uint256) public levelPrice;

    struct User {
        uint256 subscribeAmount;
        uint256 subscribeTime;
        Level   level;
        bool    subscribed;
    }

    mapping(address => User) public userInfo;

    // 等级用户列表
    mapping(Level => address[]) private levelUsers;

    uint256 public totalSubscribe;

    uint256[50] private __gap;

    event Subscribed(address indexed user, Level level, uint256 amount, uint256 time);
    event LevelPriceUpdated(Level level, uint256 newPrice);
    event RecipientUpdated(address newRecipient);

    receive() external payable {}

    function initialize(address _recipient) public initializer {
        __Ownable_init_unchained(_msgSender());
        __UUPSUpgradeable_init_unchained();
       
        recipient = _recipient;

        // 默认等级价格
        levelPrice[Level.MICRO] = 100e18;
        levelPrice[Level.BASIC] = 5000e18;
        levelPrice[Level.MIDDLE] = 20000e18;
        levelPrice[Level.ADVANCED] = 50000e18;
    }

    // 仅限 owner 升级
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    // ---------------------- 管理函数 ----------------------

    function setRecipient(address _recipient) external onlyOwner {
        require(_recipient != address(0), "Invalid recipient");
        recipient = _recipient;
        emit RecipientUpdated(_recipient);
    }

    function setLevelPrice(Level level, uint256 price) external onlyOwner {
        require(level != Level.INVALID, "Invalid level");
        require(price > 0, "Invalid price");
        levelPrice[level] = price;
        emit LevelPriceUpdated(level, price);
    }

    // ---------------------- 用户逻辑 ----------------------

    function subscribe(Level level) external nonReentrant {
        require(level != Level.INVALID, "Invalid level");
        require(!userInfo[msg.sender].subscribed, "Already subscribed");

        uint256 amount = levelPrice[level];
        require(amount > 0, "Level price not set");

        // 转账 USDT 到接收地址
        TransferHelper.safeTransferFrom(USDT, msg.sender, recipient, amount);

        userInfo[msg.sender] = User({
            subscribeAmount: amount,
            subscribeTime: block.timestamp,
            level: level,
            subscribed: true
        });

        totalSubscribe += amount;
        levelUsers[level].push(msg.sender);

        emit Subscribed(msg.sender, level, amount, block.timestamp);
    }

    // ---------------------- 视图函数 ----------------------

    function getUsers(Level level) external view returns (address[] memory) {
        require(level != Level.INVALID, "Invalid level");
        return levelUsers[level];
    }

    function getUsersLength(Level level) external view returns (uint256) {
        require(level != Level.INVALID, "Invalid level");
        return levelUsers[level].length;
    }

    function getUsersPage(Level level, uint256 start, uint256 count) external view returns (address[] memory users) {
        address[] storage arr = levelUsers[level];
        if (start >= arr.length) return new address[](0);

        uint256 end = start + count;
        if (end > arr.length) end = arr.length;

        users = new address[](end - start);
        for (uint256 i = start; i < end; i++) {
            users[i - start] = arr[i];
        }
    }

    function getSubscribeInfo()external view returns (uint256 totalUsers, uint256 totalAmount){
        totalUsers =
            levelUsers[Level.MICRO].length +
            levelUsers[Level.BASIC].length +
            levelUsers[Level.MIDDLE].length +
            levelUsers[Level.ADVANCED].length;

        totalAmount = totalSubscribe;
    }

    function getUserLevel(address user) external view returns (Level) {
        return userInfo[user].level;
    }

    function getUserInfo(address user)external view returns (uint256 amount,uint256 time,Level level,bool subscribed){
        User memory u = userInfo[user];
        return (u.subscribeAmount, u.subscribeTime, u.level, u.subscribed);
    }
}
