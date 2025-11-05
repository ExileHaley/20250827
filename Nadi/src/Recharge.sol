// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TransferHelper} from "./libraries/TransferHelper.sol";
import {ReentrancyGuard} from "./libraries/ReentrancyGuard.sol";


contract Recharge is Initializable, OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuard{

    enum Mode{Invalid,Full,Proportional}

    address public admin;
    address public recipient;
    address public sender;

    address public percent50;
    address public percent40;
    address public percent10;


    event AdminshipTransferred(address indexed previousAdmin, address indexed newAdmin);
    event MultiRecharge(address user, address token0, uint256 amount0, address token1, uint256 amount1, string remark);
    event Withdraw(string remark, address token, address to, uint256 amount);


    receive() external payable{}

    modifier onlyAdmin() {
        require(msg.sender == admin, "ERROR_ADMIN.");
        _;
    }


    function changeAdmin(address _newAdmin) external onlyOwner {
        require(_newAdmin != address(0), "ZERO_ADDRESS.");
        emit AdminshipTransferred(admin, _newAdmin);
        admin = _newAdmin;
    }

    function changeRecipient(address _newRecipient) external onlyAdmin {
        require(_newRecipient != address(0), "ZERO_ADDRESS.");
        recipient = _newRecipient;
    }


    function changeSender(address _newSender) external onlyAdmin(){
        require(_newSender != address(0), "ZERO_ADDRESS.");
        sender = _newSender;
    }

    // Authorize contract upgrades only by the owner
    function _authorizeUpgrade(address newImplementation) internal view override onlyOwner(){}

    function initialize(
        address _admin,
        address _recipient,
        address _sender,
        address _percent50,
        address _percent40,
        address _percent10
    ) public initializer {
        __Ownable_init(_msgSender());
        admin = _admin;
        recipient = _recipient;
        sender = _sender;
        percent50 = _percent50;
        percent40 = _percent40;
        percent10 = _percent10;
    }

    function singleRecharge(Mode mode, address token, uint256 amount, string calldata remark) external payable nonReentrant{
        require(amount > 0, "ERROR_AMOUNT");

        address[] memory tokens = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        tokens[0] = token;
        amounts[0] = amount;

        _recharge(mode, tokens, amounts);

        // emit SingleRecharge(msg.sender, token, amount, remark);
        emit MultiRecharge(msg.sender, token, amount, address(0), 0, remark);
    }

    /**
     * @dev 双币充值（支持 ERC20 + ERC20 / ERC20 + ETH / ETH + ERC20 / ETH + ETH）
     */
    function multiRecharge(
        Mode    mode,
        address token0,
        uint256 amount0,
        address token1,
        uint256 amount1,
        string calldata remark
    ) external payable nonReentrant{
        require(amount0 > 0 || amount1 > 0, "ERROR_AMOUNT");

        address[] memory tokens = new address[](2);
        uint256[] memory amounts = new uint256[](2);
        tokens[0] = token0;
        amounts[0] = amount0;
        tokens[1] = token1;
        amounts[1] = amount1;

        _recharge(mode, tokens, amounts);

        emit MultiRecharge(msg.sender, token0, amount0, token1, amount1, remark);
    }

    // --- 核心充值逻辑（优化版） ---
    function _recharge(Mode mode, address[] memory tokens, uint256[] memory amounts) internal {
        require(tokens.length == amounts.length, "MISMATCH_LENGTH");
        require(mode != Mode.Invalid, "INVALID_MODE");

        // 如果按比例分发，确保分发地址已设置
        if (mode == Mode.Proportional) {
            require(percent50 != address(0) && percent40 != address(0) && percent10 != address(0), "PERCENT_ADDR_NOT_SET");
        }

        uint256 totalETHRequired = 0;
        bool hasETH = false;

        // 遍历所有币种（ERC20 或 ETH(=address(0)））
        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            uint256 amount = amounts[i];
            if (amount == 0) continue;

            if (token == address(0)) {
                // 收集 ETH 总额，ETH 真正的转移会在循环外一次性按策略分发
                totalETHRequired += amount;
                hasETH = true;
                continue;
            }

            // ERC20 处理（立即从 msg.sender 扣并分发）
            if (mode == Mode.Full) {
                // 全额到账到 recipient
                // TransferHelper.safeTransferFrom 在失败时应 revert
                TransferHelper.safeTransferFrom(token, msg.sender, recipient, amount);
            } else { // Mode.Proportional
                // 按 50% / 40% / 10% 分配
                // 使用最后一份为剩余值以避免舍入误差
                uint256 amt50 = (amount * 50) / 100;
                uint256 amt40 = (amount * 40) / 100;
                uint256 amt10 = amount - amt50 - amt40;

                if (amt50 > 0) TransferHelper.safeTransferFrom(token, msg.sender, percent50, amt50);
                if (amt40 > 0) TransferHelper.safeTransferFrom(token, msg.sender, percent40, amt40);
                if (amt10 > 0) TransferHelper.safeTransferFrom(token, msg.sender, percent10, amt10);
            }
        }

        // ETH 在这里统一分发（如果存在 ETH）
        if (hasETH) {
            // 确认 msg.value 足够
            require(msg.value >= totalETHRequired, "ERROR_PAYABLE_AMOUNT");

            if (mode == Mode.Full) {
                // 全部打给 recipient
                if (totalETHRequired > 0) {
                    TransferHelper.safeTransferETH(recipient, totalETHRequired);
                }
            } else {
                // Proportional 模式按 50/40/10 分配
                uint256 eth50 = (totalETHRequired * 50) / 100;
                uint256 eth40 = (totalETHRequired * 40) / 100;
                uint256 eth10 = totalETHRequired - eth50 - eth40;

                if (eth50 > 0) TransferHelper.safeTransferETH(percent50, eth50);
                if (eth40 > 0) TransferHelper.safeTransferETH(percent40, eth40);
                if (eth10 > 0) TransferHelper.safeTransferETH(percent10, eth10);
            }

            // 退回多余的 ETH（用户可能多付）
            uint256 refund = msg.value - totalETHRequired;
            if (refund > 0) {
                TransferHelper.safeTransferETH(msg.sender, refund);
            }
        } else {
            // 如果没有 ETH 要求 msg.value 必须为 0，避免误传 ETH
            require(msg.value == 0, "NO_ETH_REQUIRED");
        }
    }


    function withdraw(string memory remark, address token, uint256 amount, address to) external onlyAdmin(){
        require(amount > 0 && to != address(0),"ERROR_AMOUNT_AND_TO.");
        if(token != address(0)) TransferHelper.safeTransferFrom(token, sender, to, amount);
        else TransferHelper.safeTransferETH(to, amount);
        emit Withdraw(remark, token, to, amount);
    }



    
    


}