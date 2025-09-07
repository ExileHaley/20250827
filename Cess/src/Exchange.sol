// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {TransferHelper} from "./libraries/TransferHelper.sol";
import {ReentrancyGuard} from "./libraries/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Exchange is Initializable, OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuard {
    address public cessToken;   // 输入代币
    address public cfunToken;   // 输出代币
    uint256 public exchangeRate; // 兑换比例 (cfun per cess, 1e18 精度)

    event Exchanged(address indexed user, uint256 cessAmount, uint256 cfunAmount);
    event ExchangeRateUpdated(uint256 numerator, uint256 denominator, uint256 rate);

    function initialize(
        address _cessToken,
        uint256 _exchangeRate
    ) public initializer {
        __Ownable_init(_msgSender());
        __UUPSUpgradeable_init();
        cessToken = _cessToken;
        exchangeRate = _exchangeRate; // 初始化时直接传入 1e18 = 1:1
    }

    // Authorize contract upgrades only by the owner
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function setCfunToken(address _cfunToken) external onlyOwner{
        cfunToken = _cfunToken;
    }

    function getBalance(address token, address user) external view returns(uint256 amount){
        amount = IERC20(token).balanceOf(user);
    }

    /// @notice 设置兑换比例，例如 setExchangeRate(3, 2) 表示 1 CESS = 1.5 CFUN
    function setExchangeRate(uint256 numerator, uint256 denominator) external onlyOwner {
        require(numerator > 0 && denominator > 0, "invalid ratio");
        exchangeRate = (numerator * 1e18) / denominator;
        emit ExchangeRateUpdated(numerator, denominator, exchangeRate);
    }

    function getExchangeResult(uint256 cessAmount) public view returns (uint256 cfunAmount) {
        cfunAmount = cessAmount * exchangeRate / 1e18;
    }

    function exchange(uint256 cessAmount) external nonReentrant {
        require(cessAmount > 0, "amount=0");

        uint256 cfunAmount = getExchangeResult(cessAmount);

        // 用户先 approve 给合约
        TransferHelper.safeTransferFrom(cessToken, msg.sender, address(this), cessAmount);

        // 确保合约里有足够的 CFUN 余额
        uint256 cfunBalance = IERC20(cfunToken).balanceOf(address(this));
        require(cfunBalance >= cfunAmount, "insufficient CFUN liquidity");

        // 给用户转 CFUN
        TransferHelper.safeTransfer(cfunToken, msg.sender, cfunAmount);

        emit Exchanged(msg.sender, cessAmount, cfunAmount);
    }
}
