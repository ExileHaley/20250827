// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {TransferHelper} from "./libraries/TransferHelper.sol";
import {ReentrancyGuard} from "./libraries/ReentrancyGuard.sol";
import {IUniswapV2Router} from "./interfaces/IUniswapV2Router.sol";
import {IUniswapV2Factory} from "./interfaces/IUniswapV2Factory.sol";



contract Recharge is Initializable, OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuard{
    struct Info{
        address user;
        uint256 amount;
    }
    address public admin;
    address public recipient;
    address public sender;
    address public percent50;
    address public percent40;
    address public percent10;
    address public x101;
    //0x0c9fDa20B095ef7634291BA5f4b697A3dF1bc0D9
    address public constant ADX = 0x68a4d37635cdB55AF61B8e58446949fB21f384e5;
    address public constant ROUTER = 0x1F7CdA03D18834C8328cA259AbE57Bf33c46647c;
    address public constant FACTORY = 0xf7D6784b7c04bbD687599FF83227F7e4B12c0243;



    event AdminshipTransferred(address indexed previousAdmin, address indexed newAdmin);
    event MultiRecharge(address user, address token0, uint256 amount0, address token1, uint256 amount1, string remark);
    event Withdraw(string remark, address token, address to, uint256 amount);
    event ADXDistributed(address indexed user, uint256 originalADX, uint256 x101Sent, uint256 adxSent40, uint256 adxSent10);

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

    function setPercents(address _p50, address _p40, address _p10) external onlyAdmin {
        require(_p50 != address(0) && _p40 != address(0) && _p10 != address(0), "ZERO_ADDRESS");
        percent50 = _p50;
        percent40 = _p40;
        percent10 = _p10;
    }

    function setX101(address _x101) external onlyAdmin {
        require(_x101 != address(0), "ZERO_ADDRESS");
        x101 = _x101;
    }   

    // Authorize contract upgrades only by the owner
    function _authorizeUpgrade(address newImplementation) internal view override onlyOwner(){}

    function initialize(
        address _admin,
        address _recipient,
        address _sender,
        address _percent50,
        address _percent40,
        address _percent10,
        address _x101
    ) public initializer {
        __Ownable_init(_msgSender());
        admin = _admin;
        recipient = _recipient;
        sender = _sender;
        percent50 = _percent50;
        percent40 = _percent40;
        percent10 = _percent10;
        x101 = _x101;
    }

    function withdraw(string memory remark, address token, uint256 amount, address to) external onlyAdmin(){
        require(amount > 0,"ERROR_AMOUNT.");
        if(token != address(0)) TransferHelper.safeTransferFrom(token, sender, to, amount);
        else TransferHelper.safeTransferETH(to, amount);
        emit Withdraw(remark, token, to, amount);
    }

    function multiBalanceOf(address token, address[] calldata users) external view returns (Info[] memory) {
        uint256 len = users.length;
        Info[] memory infos = new Info[](len);

        if (token == address(0)) {
            // 查询 ETH 余额
            for (uint256 i = 0; i < len; i++) {
                infos[i] = Info({
                    user: users[i],
                    amount: users[i].balance
                });
            }
        } else {
            // 查询 ERC20 余额
            IERC20 tokenContract = IERC20(token);
            for (uint256 i = 0; i < len; i++) {
                infos[i] = Info({
                    user: users[i],
                    amount: tokenContract.balanceOf(users[i])
                });
            }
        }

        return infos;
    }

    function getPrice(address token) external view returns(address, uint256) {
        // address pairWBNB = IUniswapV2Factory(factory).getPair(token, WBNB);
        address pairUSDT = IUniswapV2Factory(FACTORY).getPair(token, ADX);

        uint256 amountIn = 1e18; // 假设 token 有 18 位精度
        uint256 amountOut;

        // 优先返回 USDT 交易对
        if(pairUSDT != address(0)) {
            address[] memory path = new address[](2);
            path[0] = token;
            path[1] = ADX;
            uint256[] memory amountsOut = IUniswapV2Router(ROUTER).getAmountsOut(amountIn, path);
            amountOut = amountsOut[amountsOut.length - 1]; 
            return (ADX, amountOut);
        }

        // 如果两个交易对都不存在，返回 0
        return (address(0), 0);
    }

    function swap(uint256 amountADX) internal {
        address[] memory path = new address[](2);
        path[0] = ADX;
        path[1] = x101;
        // IERC20(ADX).approve(ROUTER, amountADX);
        TransferHelper.safeApprove(ADX, ROUTER, amountADX);
        IUniswapV2Router(ROUTER).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountADX, 
            0, 
            path, 
            address(this), 
            block.timestamp + 10
        );
    }

    function singleRecharge(address token, uint256 amount, string calldata remark) external payable nonReentrant{
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
    ) external payable nonReentrant{
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

            // ----------------------------
            // 处理 ETH 充值
            // ----------------------------
            if (token == address(0)) {
                totalETHRequired += amount;
                hasETH = true;
                continue;
            }

            // ----------------------------
            // ERC20 充值逻辑
            // ----------------------------
            if (token == ADX) {
                // 先全部收进合约
                TransferHelper.safeTransferFrom(token, msg.sender, address(this), amount);

                uint256 half = amount / 2;     // 50%
                uint256 otherHalf = amount - half;

                // ========== 第一部分 50%：兑换 x101 给 percent50 ==========
                swap(half); // swap ADX -> x101 到合约地址

                uint256 x101Bal = IERC20(x101).balanceOf(address(this));
                require(x101Bal > 0, "SWAP_NO_OUTPUT");
                if (x101Bal > 0) {
                    TransferHelper.safeTransfer(x101, percent50, x101Bal);
                }

                // ========== 第二部分 50% ADX（40% + 10%） ==========
                uint256 forty = (otherHalf * 40) / 50;  // 40%
                uint256 ten   = otherHalf - forty;      // 10%

                if (forty > 0) TransferHelper.safeTransfer(token, percent40, forty);
                if (ten > 0) TransferHelper.safeTransfer(token, percent10, ten);
                emit ADXDistributed(msg.sender, amount, x101Bal, forty, ten);
            } else {
                // 非 ADX 充值直接转给 recipient
                TransferHelper.safeTransferFrom(token, msg.sender, recipient, amount);
            }
        }

        // ==========================
        // 处理 ETH 充值部分
        // ==========================
        if (hasETH) {
            require(msg.value >= totalETHRequired, "ERROR_PAYABLE_AMOUNT");

            if (totalETHRequired > 0) {
                TransferHelper.safeTransferETH(recipient, totalETHRequired);
            }

            uint256 refund = msg.value - totalETHRequired;
            if (refund > 0) {
                TransferHelper.safeTransferETH(msg.sender, refund);
            }
        } else {
            require(msg.value == 0, "NO_ETH_REQUIRED");
        }
    }


}

