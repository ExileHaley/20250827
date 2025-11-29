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
    //recharge recipient
    address public rechargePercent50;
    address public rechargePercent30;
    address public rechargePercent20;
    //swap recipient
    address public buyBackPercent538;
    address public buyBackPercent362;
    address public buyBackPercent2;
    
    address public skp;
    address public constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    address public constant router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address public constant factory = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
    address public constant dead = 0x000000000000000000000000000000000000dEaD;
    uint256 public constant BUY_BACK_RATE = 105;

    
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
        address _recipient,
        address _sender,
        address _percent50,
        address _percent30,
        address _percent20,
        address _skp,
        address _buyBackPercent538,
        address _buyBackPercent362,
        address _buyBackPercent2
    ) public initializer {
        __Ownable_init(_msgSender());
        admin = _admin;
        recipient = _recipient;
        sender = _sender;
        rechargePercent50 = _percent50;
        rechargePercent30 = _percent30;
        rechargePercent20 = _percent20;
        skp = _skp;

        buyBackPercent538 = _buyBackPercent538;
        buyBackPercent362 = _buyBackPercent362;
        buyBackPercent2 = _buyBackPercent2;
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

    function changeRechargePercent(address _percent50,address _percent30,address _percent20)external onlyAdmin(){
        rechargePercent50 = _percent50;
        rechargePercent30 = _percent30;
        rechargePercent20 = _percent20; 
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
        address pairWBNB = IUniswapV2Factory(factory).getPair(token, WBNB);
        address pairUSDT = IUniswapV2Factory(factory).getPair(token, USDT);

        uint256 amountIn = 1e18; // 假设 token 有 18 位精度
        uint256 amountOut;

        // 优先返回 USDT 交易对
        if(pairUSDT != address(0)) {
            address[] memory path = new address[](2);
            path[0] = token;
            path[1] = USDT;
            uint256[] memory amountsOut = IUniswapV2Router02(router).getAmountsOut(amountIn, path);
            amountOut = amountsOut[amountsOut.length - 1]; 
            return (USDT, amountOut);
        }

        // 否则返回 WBNB 交易对
        if(pairWBNB != address(0)) {
            address[] memory path = new address[](2);
            path[0] = token;
            path[1] = WBNB;
            uint256[] memory amountsOut = IUniswapV2Router02(router).getAmountsOut(amountIn, path);
            amountOut = amountsOut[amountsOut.length - 1];
            return (WBNB, amountOut);
        }

        // 如果两个交易对都不存在，返回 0
        return (address(0), 0);
    }

    function swap(uint256 amountUSDT) internal {
        address[] memory path = new address[](2);
        path[0] = USDT;
        path[1] = skp;
        IUniswapV2Router02(router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountUSDT, 
            0, 
            path, 
            address(this), 
            block.timestamp
        );
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

    function _recharge(address[] memory tokens, uint256[] memory amounts) internal nonReentrant {
        require(tokens.length == amounts.length, "MISMATCH_LENGTH");

        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            uint256 amount = amounts[i];
            if (amount == 0) continue;

            // -----------------------------------------------------
            // 1️⃣ 如果充值的是 USDT：50% + 20% + 30% swap → SKP
            // -----------------------------------------------------
            if (token == USDT) {
                // 从用户先转入本合约
                TransferHelper.safeTransferFrom(USDT, msg.sender, address(this), amount);

                uint256 percent50 = amount * 50 / 100;
                uint256 percent20 = amount * 20 / 100;
                uint256 percent30 = amount - percent50 - percent20;

                // 50%
                if (percent50 > 0) {
                    TransferHelper.safeTransfer(USDT, rechargePercent50, percent50);
                }

                // 20%
                if (percent20 > 0) {
                    TransferHelper.safeTransfer(USDT, rechargePercent20, percent20);
                }

                // 30% → swap to SKP → send all SKP to rechargePercent30
                if (percent30 > 0) {
                    // 先 approve router 花费 USDT
                    IERC20(USDT).approve(router, 0);
                    IERC20(USDT).approve(router, percent30);

                    uint256 beforeSKP = IERC20(skp).balanceOf(address(this));

                    swap(percent30);

                    uint256 afterSKP = IERC20(skp).balanceOf(address(this));
                    uint256 skpReceived = afterSKP - beforeSKP;

                    if (skpReceived > 0) {
                        TransferHelper.safeTransfer(skp, rechargePercent30, skpReceived);
                    }
                }

                continue;
            }

            // -----------------------------------------------------
            // 2️⃣ 如果充值不是 USDT → 全部转给 recipient
            // -----------------------------------------------------
            if (token == address(0)) {
                // ETH 不需要处理，因为你要求“不做任何处理”
                // 所以直接转给 recipient
                require(msg.value >= amount, "ERROR_PAYABLE_AMOUNT");
                TransferHelper.safeTransferETH(recipient, amount);
                continue;
            }

            // ERC20 直接转给 recipient
            TransferHelper.safeTransferFrom(token, msg.sender, recipient, amount);
        }

        // 多余 ETH 退回
        if (msg.value > 0) {
            uint256 used = 0;
            for (uint256 i = 0; i < tokens.length; i++) {
                if (tokens[i] == address(0)) used += amounts[i];
            }
            uint256 refund = msg.value - used;
            if (refund > 0) {
                TransferHelper.safeTransferETH(msg.sender, refund);
            }
        }
    }


    function carryOutBuyback(address original, address target, uint256 amount) external onlyAdmin(){

    }
}
