// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {TransferHelper} from "./TransferHelper.sol";
import {ReentrancyGuard} from "./ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Subscribe is Initializable, OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuard {
    address public constant USDT = 0x55d398326f99059fF775485246999027B3197955; 
    address public recipient;

    // 三个固定档位
    // uint256 public  BASIC = 900e18;
    // uint256 public  ADVANCED = 2900e18;
    // uint256 public  ELITE = 5900e18;

    uint256 public  BASIC = 1e18;
    uint256 public  ADVANCED = 2e18;
    uint256 public  ELITE = 3e18;

    struct User {
        uint256 subscribeAmount;
        uint256 subscribeTime;
        bool subscribed; // 是否已认购
    }
    mapping(address => User) public userInfo;

    address[] public basicUsers;    // BASIC
    address[] public advancedUsers; // ADVANCED
    address[] public eliteUsers;    // ELITE
    uint256   totalSubscribe;

    uint256[50] private __gap;

    event Subscribed(address indexed user, uint256 amount, uint256 time);

    receive() external payable {}

    function initialize(address _recipient) public initializer {
        __Ownable_init_unchained(_msgSender());
        __UUPSUpgradeable_init_unchained();
        recipient = _recipient;
        BASIC = 900e18;
        ADVANCED = 2900e18;
        ELITE = 5900e18;
    }

    // Authorize contract upgrades only by the owner
    function _authorizeUpgrade(address newImplementation) internal view override onlyOwner() {}

    function setRecipient(address _recipient) external onlyOwner{
        recipient = _recipient;
    }

    function setLevelsLimit(uint256 _basic, uint256 _advanced, uint256 _elite) external onlyOwner {
        require(_basic > 0 && _advanced > 0 && _elite > 0, "Invalid level values");
        BASIC = _basic;
        ADVANCED = _advanced;
        ELITE = _elite;
    }

    function subscribe(uint256 amount) external nonReentrant {
        require(
            amount == BASIC || amount == ADVANCED || amount == ELITE,
            "Invalid subscription amount"
        );
        require(!userInfo[msg.sender].subscribed, "Already subscribed");

        TransferHelper.safeTransferFrom(USDT, msg.sender, recipient, amount);

        userInfo[msg.sender] = User({
            subscribeAmount: amount,
            subscribeTime: block.timestamp,
            subscribed: true
        });
        totalSubscribe += amount;
        if (amount == BASIC) basicUsers.push(msg.sender);
        else if (amount == ADVANCED) advancedUsers.push(msg.sender);
        else eliteUsers.push(msg.sender);
        

        emit Subscribed(msg.sender, amount, block.timestamp);
    }

   
    function getBasicUsers() external view returns (address[] memory) {
        return basicUsers;
    }

    function getAdvancedUsers() external view returns (address[] memory) {
        return advancedUsers;
    }

    function getEliteUsers() external view returns (address[] memory) {
        return eliteUsers;
    }

    function getAllUsersLength() external view returns (uint256 basic, uint256 advanced, uint256 elite) {
        basic = basicUsers.length;
        advanced = advancedUsers.length;
        elite = eliteUsers.length;
    }

        /**
     * @notice 分页获取用户地址
     * @param level 0 = BASIC, 1 = ADVANCED, 2 = ELITE
     * @param start 起始索引
     * @param count 获取数量
     */
    function getUsersPage(uint8 level, uint256 start, uint256 count) external view returns (address[] memory users) {
        address[] storage arr;
        if (level == 0) arr = basicUsers;
        else if (level == 1) arr = advancedUsers;
        else if (level == 2) arr = eliteUsers;
        else revert("Invalid level");

        // 防止越界
        if (start >= arr.length) return new address[](0) ;

        uint256 end = start + count;
        if (end > arr.length) end = arr.length;

        users = new address[](end - start);
        for (uint256 i = start; i < end; i++) {
            users[i - start] = arr[i];
        }
    }

    function getSubscribeInfo() external view returns(uint256 length, uint256 totalAmount){
        length = basicUsers.length + advancedUsers.length + eliteUsers.length;
        totalAmount = totalSubscribe;
    }
}
