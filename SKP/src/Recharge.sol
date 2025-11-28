// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {TransferHelper} from "./libraries/TransferHelper.sol";
import {ReentrancyGuard} from "./libraries/ReentrancyGuard.sol";
import {IUniswapV2Router02} from "./interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Factory} from "./interfaces/IUniswapV2Factory.sol";



contract Recharge is Initializable, OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuard{
    address public admin;
    address public operator;
    address public recipient;
    address public sender;
    address public percent50;
    address public percent30;
    address public percent20;

    address public constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    address public constant router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address public constant factory = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;

    
    struct Info{
        address user;
        uint256 amount;
    }

    event AdminshipTransferred(address indexed previousAdmin, address indexed newAdmin);
    event MultiRecharge(address user, address token0, uint256 amount0, address token1, uint256 amount1, string remark);
    event Withdraw(string remark, address token, address to, uint256 amount);

    receive() external payable{}

    modifier onlyAdmin() {
        require(msg.sender == admin, "ERROR_ADMIN.");
        _;
    }

    function _authorizeUpgrade(address newImplementation) internal view override onlyOwner(){}

    function initialize(
        address _admin,
        address _sender,
        address _percent50,
        address _percent30,
        address _percent20
    ) public initializer {
        __Ownable_init(_msgSender());
        admin = _admin;
        sender = _sender;
        percent50 = _percent50;
        percent30 = _percent30;
        percent20 = _percent20;
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

    function changeSender(address _newSender) external onlyAdmin(){
        require(_newSender != address(0), "ZERO_ADDRESS.");
        sender = _newSender;
    }


    
}