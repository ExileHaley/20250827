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
import {IUniswapV2Pair} from "./interfaces/IUniswapV2Pair.sol";
import {ILiquidity} from "./interfaces/ILiquidity.sol";
import {Errors} from "./libraries/Errors.sol";

contract LiquidityManager is Initializable, OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuard, ILiquidity{
    IUniswapV2Router02 public constant pancakeRouter = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    address public constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address public token;
    address public subToken;


    address public staking;
    
    receive() external payable {
        revert("NO_DIRECT_SEND");
    }

    modifier onlyStaking() {
        require(staking == msg.sender, "Not permit.");
        _;
    }

    function initialize(
        address _token,
        address _subToken
    ) public initializer {
        __Ownable_init(_msgSender());
        token = _token;
        subToken = _subToken;
    }

    // Authorize contract upgrades only by the owner
    function _authorizeUpgrade(address newImplementation) internal view override onlyOwner(){}

    function setStaking(address _staking) external onlyOwner{
        staking = _staking;
    }

    //买入字币给用户
    function swapForSubTokenToUser(address to, uint256 amountUSDT) external override onlyStaking{
        if (amountUSDT == 0) return ;
        _executeSwap(USDT, subToken, amountUSDT);
        uint256 subTokenBalance = IERC20(subToken).balanceOf(address(this));
        TransferHelper.safeTransfer(subToken, to, subTokenBalance);
    }
    //买入子币销毁
    function swapForSubTokenToBurn(uint256 amountUSDT) external override onlyStaking{
        if (amountUSDT == 0) return ;
        _executeSwap(USDT, subToken, amountUSDT);
        uint256 subTokenBalance = IERC20(subToken).balanceOf(address(this));
        TransferHelper.safeTransfer(subToken, DEAD, subTokenBalance);
    }

    

    function _executeSwap(address fromToken, address toToken, uint256 fromAmount) private{
        address[] memory path = new address[](2);
        path[0] = fromToken;
        path[1] = toToken;
        
        // 执行 token → USDT 的交换
        IERC20(fromToken).approve(address(pancakeRouter), fromAmount);
        pancakeRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            fromAmount,
            0,
            path,
            address(this),
            block.timestamp + 30
        );
    }

    function addLiquidity(uint256 amountUSDT) external override onlyStaking{
        uint256 oneHalf = amountUSDT / 2;
        uint256 beforeBalance = IERC20(token).balanceOf(address(this));
        _executeSwap(USDT, token, oneHalf);
        uint256 afterBalance = IERC20(token).balanceOf(address(this));

        uint256 toLiquidityUSDT = amountUSDT - oneHalf;
        uint256 toLiquidityToken = afterBalance - beforeBalance;

        IERC20(USDT).approve(address(pancakeRouter), toLiquidityUSDT);
        IERC20(token).approve(address(pancakeRouter), toLiquidityToken);

        pancakeRouter.addLiquidity(
            USDT,
            token,
            toLiquidityUSDT,
            toLiquidityToken,
            0,
            0,
            address(this),
            block.timestamp + 30
        );

    }



    // function acquireSpecifiedUsdt(address to, uint256 amountUSDT) external override onlyStaking {
    //     // 1. 获取 LP token 并移除流动性
    //     address pair = IUniswapV2Factory(pancakeRouter.factory()).getPair(USDT, token);
    //     uint256 lpTokenBalance = IERC20(pair).balanceOf(address(this));
    //     if (lpTokenBalance == 0) revert Errors.NoLiquidity(); // 如果没有流动性则抛出错误
        
    //     uint256 totalLP = lpTokenBalance; // 计算 LP 总量
    //     // 计算需要的 LP
    //     uint256 lpNeeded = amountUSDT * 1e18 / _getLPValue(totalLP);

    //     // 确保你有足够的 LP token
    //     if (lpNeeded > lpTokenBalance) revert Errors.InsufficientLP();

    //     // 2. 移除流动性并获取 USDT 和 token
    //     (uint256 amountUSDTFromLP, uint256 amountTokenFromLP) = pancakeRouter.removeLiquidity(
    //         USDT,
    //         token,
    //         lpNeeded,
    //         0,
    //         0,
    //         address(this),
    //         block.timestamp + 30
    //     );

    //     // 3. 将移除流动性所得的 token 卖出为 USDT
    //     uint256 tokenToUSDT = _swapTokenToUSDT(amountTokenFromLP);

    //     // 4. 计算实际转账的 USDT 数量并转账
    //     uint256 totalUSDT = amountUSDTFromLP + tokenToUSDT;
    //     if (totalUSDT < amountUSDT) revert Errors.InsufficientLiquidity(); // 如果移除流动性后的 USDT 不足，则抛出错误

    //     // 5. 转账 目标地址 to，扣除手续费 5e18
    //     uint256 transferAmount = totalUSDT - 5e18;
    //     TransferHelper.safeTransfer(USDT, to, transferAmount);

    //     // 6. 将 5e18 的 USDT 转换为 subToken，并转到 DEAD 地址
    //     _burnSubToken(5e18);
    // }

    // function _burnSubToken(uint256 amountUSDT) private{
    //     if (amountUSDT == 0) return ;
    //     _executeSwap(USDT, subToken, amountUSDT);
    //     uint256 subTokenBalance = IERC20(subToken).balanceOf(address(this));
    //     TransferHelper.safeTransfer(subToken, DEAD, subTokenBalance);
    // }

    // function _getLPValue(uint256 totalLP) internal view returns(uint256) {
    //     address pair = IUniswapV2Factory(pancakeRouter.factory()).getPair(USDT, token);
    //     // require(pair != address(0), "Pair does not exist");
    //     if(pair == address(0)) revert Errors.PairNotExist();

    //     (uint112 reserveUSDT, uint112 reserveToken, ) = IUniswapV2Pair(pair).getReserves();
    //     uint256 usdtPerLP = reserveUSDT * 1e18 / totalLP;
    //     uint256 tokenPerLP = reserveToken * 1e18 / totalLP;

    //     // 获取 token 的价格
    //     address[] memory path = new address[](2);
    //     path[0] = token;
    //     path[1] = USDT;

    //     uint256[] memory amounts = pancakeRouter.getAmountsOut(tokenPerLP, path);
    //     uint256 tokenToUSDT = amounts[1];

    //     uint256 lpValue = usdtPerLP + tokenToUSDT;
    //     return lpValue;
    // }

    // function _swapTokenToUSDT(uint256 amountToken) internal returns(uint256) {
    //     address[] memory path = new address[](2);
    //     path[0] = token;
    //     path[1] = USDT;
        
    //     // 执行 token → USDT 的交换
    //     IERC20(token).approve(address(pancakeRouter), amountToken);
    //     uint256[] memory amountsOut = pancakeRouter.getAmountsOut(amountToken, path);

    //     pancakeRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
    //         amountToken,
    //         0,
    //         path,
    //         address(this),
    //         block.timestamp + 30
    //     );

    //     uint256 usdtBalanceAfter = IERC20(USDT).balanceOf(address(this));
    //     uint256 amountUSDT = usdtBalanceAfter - amountsOut[0];
        
    //     return amountUSDT;
    // }

    function acquireSpecifiedUsdt(address to, uint256 needUSDT) external onlyStaking {

        if(needUSDT <= 5e18) revert Errors.InvalidAmount();
        address pair = IUniswapV2Factory(pancakeRouter.factory()).getPair(USDT, token);
        uint256 lpTokenBalance = IERC20(pair).balanceOf(address(this));
        if (lpTokenBalance == 0) revert Errors.NoLiquidity(); // 如果没有流动性则抛出错误
        (uint256 tokenAmount, uint256 usdtAmount) = quoteLPValue(pair);

        address[] memory path = new address[](2);
        path[0] = token;  // 输入 token
        path[1] = USDT; 
        uint[] memory amounts = IUniswapV2Router02(pancakeRouter).getAmountsIn(needUSDT / 2, path);

        uint256 requiredLpByToken = amounts[0] * 1e18 / tokenAmount;
        uint256 requiredLpByUSDT = needUSDT / 2 * 1e18 / usdtAmount;
        uint256 lpToRemove = requiredLpByToken > requiredLpByUSDT ? requiredLpByToken : requiredLpByUSDT;
        if(lpToRemove > lpTokenBalance) revert Errors.InsufficientLiquidity();
        removeLiquidity(pair, lpToRemove);

        uint256 tokenBalance = IERC20(token).balanceOf(address(this));
        TransferHelper.safeApprove(token, address(pancakeRouter), tokenBalance);
        IUniswapV2Router02(pancakeRouter).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenBalance, 
            0, 
            path, 
            address(this), 
            block.timestamp + 30
        );
        
        uint256 amountUSDT = IERC20(USDT).balanceOf(address(this));
        if(amountUSDT < needUSDT) revert Errors.AmountTooLow();
        TransferHelper.safeTransfer(USDT, to, needUSDT - 5e18);
        _burnSubToken(5e18);
    }

    function getNeedLP(uint256 amountUSDT) external view returns(uint256){
        address pair = IUniswapV2Factory(pancakeRouter.factory()).getPair(USDT, token);
        // uint256 lpTokenBalance = IERC20(pair).balanceOf(address(this));
        (uint256 tokenAmount, uint256 usdtAmount) = quoteLPValue(pair);
         address[] memory path = new address[](2);
        path[0] = token;  // 输入 token
        path[1] = USDT; 
        uint[] memory amounts = IUniswapV2Router02(pancakeRouter).getAmountsIn(amountUSDT / 2, path);

        uint256 requiredLpByToken = amounts[0] * 1e18 / tokenAmount;
        uint256 requiredLpByUSDT = amountUSDT / 2 * 1e18 / usdtAmount;
        uint256 lpToRemove = requiredLpByToken > requiredLpByUSDT ? requiredLpByToken : requiredLpByUSDT;

        return lpToRemove;
    }


    function removeLiquidity(address pair, uint256 amountLP) private{
        TransferHelper.safeApprove(pair, address(pancakeRouter), amountLP);
        IUniswapV2Router02(pancakeRouter).removeLiquidity(
            token, 
            USDT, 
            amountLP, 
            0, 
            0, 
            address(this), 
            block.timestamp
        );
    }

    function quoteLPValue(address pair)
        public
        view
        returns (uint256 tokenAmount, uint256 usdtAmount)
    {
        (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(pair).getReserves();
        uint256 totalLP = IUniswapV2Pair(pair).totalSupply();

        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();

        require(token0 == token || token1 == token, "token not in pair");
        require(token0 == USDT || token1 == USDT, "USDT not in pair");

        if (token0 == token && token1 == USDT) {
            tokenAmount = uint256(reserve0) * 1e18 / totalLP;
            usdtAmount  = uint256(reserve1) * 1e18 / totalLP;
        } else if (token0 == USDT && token1 == token) {
            tokenAmount = uint256(reserve1) * 1e18 / totalLP;
            usdtAmount  = uint256(reserve0) * 1e18 / totalLP;
        } else {
            revert("invalid pair");
        }
    }


    // -------------------------
    // 将指定的 USDT 兑换为 subToken 并转给 DEAD（销毁）
    // -------------------------
    function _burnSubToken(uint256 amountUSDT) private {
        if (amountUSDT == 0) return;

        address[] memory path = new address[](2);
        path[0] = USDT;
        path[1] = subToken;

        uint256 beforeSwap = IERC20(subToken).balanceOf(address(this));

        TransferHelper.safeApprove(USDT, address(pancakeRouter), amountUSDT);

        pancakeRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountUSDT,
            0,
            path,
            address(this),
            block.timestamp + 60
        );

        uint256 afterSwap = IERC20(subToken).balanceOf(address(this));
        uint256 got = afterSwap - beforeSwap;
        if (got > 0) {
            TransferHelper.safeTransfer(subToken, DEAD, got);
        }
    }

}

