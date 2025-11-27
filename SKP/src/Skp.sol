// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPancakeFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IPancakeRouter02 {
    function factory() external pure returns (address);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IPancakePair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

contract Skp is ERC20, Ownable{

    event Buyback(address buyer, uint256 usdtSpent, uint256 skpBought);
    event SwapAndSendTax(address recipient, uint256 tokensSwapped);
    event SetAllowlist(address indexed user, bool allow);
    event SellFee(address from, uint256 amount, uint256 fee);
    //constant param init
    IPancakeRouter02 public pancakeRouter = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    address public constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    uint256 public constant SELL_RATE = 5;
    uint256 public constant BUYBACK_RATE = 105;
    //pair
    address public pancakePair;
    //init param
    address public sellFee;
    address public buyBackWallet;
    address public attributableToBuyBackWallet;
    //status param
    bool    private swapping;
    //allowlist
    mapping(address => bool) public allowlist;
    
    constructor(address _initialRecipient,address _sellFee, address _buyBackWallet, address _attributableToBuyBackWallet)ERC20("SKP","SKP")Ownable(msg.sender){

        _mint(_initialRecipient, 2100000e18);
        sellFee = _sellFee;
        buyBackWallet = _buyBackWallet;
        attributableToBuyBackWallet = _attributableToBuyBackWallet;

        pancakePair = IPancakeFactory(pancakeRouter.factory())
            .createPair(address(this), USDT);
        allowlist[_initialRecipient] = true;
        allowlist[_sellFee] = true;
        
    }

    function setAddrs(address _sellFee, address _buyBackWallet, address _attributableToBuyBackWallet) external onlyOwner(){
        sellFee = _sellFee;
        buyBackWallet = _buyBackWallet;
        attributableToBuyBackWallet = _attributableToBuyBackWallet;
    }

    function setAllowlist(address addr, bool isAllow) public onlyOwner {
        allowlist[addr] = isAllow;
        emit SetAllowlist(addr, isAllow);
    }

    function _update(address from, address to, uint256 amount) internal virtual override{
        //status control
        if (swapping) {
            super._update(from, to, amount);
            return;
        }

        // mint and burn
        if (from == address(0) || to == address(0)) {
            super._update(from, to, amount);
            return;
        }

        // allow list
        if (allowlist[from] || allowlist[to]) {
            super._update(from, to, amount);
            return;
        }

        bool isBuy = from == pancakePair;
        bool isSell = to == pancakePair;

        if (isBuy) {
            revert("BUY_NOT_ALLOWED");
        }

        if (isSell) {
            
            _tryBuyBack(amount);
            //compute fee
            uint256 fee = (amount * SELL_RATE) / 100; // 5%
            super._update(from, address(this), fee);
            _processFee(fee, sellFee);

            uint256 sendAmount = amount - fee;
            super._update(from, to, sendAmount);
            emit SellFee(from, amount, fee);
            return;
        }
        super._update(from, to, amount);
    }

    function _processFee(uint256 amountToken, address to) private{
        if (amountToken == 0) return ;
        //update status
        swapping = true;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = USDT;
        _approve(address(this), address(pancakeRouter), amountToken);
         try pancakeRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountToken,
            0, 
            path,
            to,
            block.timestamp + 30
        ) {
            emit SwapAndSendTax(to, amountToken);
        }catch{}
        //update status
        swapping = false;
    }

    function _tryBuyBack(uint256 soldAmount) private {
        if (buyBackWallet == address(0) || attributableToBuyBackWallet == address(0)) return;
        //compute usdt need
        uint256 buyAmount = (soldAmount * BUYBACK_RATE) / 100; // 105%
        uint256 usdtNeeded = _getUSDTRequired(buyAmount);
        if (usdtNeeded == 0) return;

        //swap condtion
        uint256 balance = IERC20(USDT).balanceOf(buyBackWallet);
        uint256 allow = IERC20(USDT).allowance(buyBackWallet, address(this));
        if (balance < usdtNeeded || allow < usdtNeeded) return;

        IERC20(USDT).transferFrom(buyBackWallet, address(this), usdtNeeded);
        //excute swap
        swapping = true;
        address[] memory path = new address[](2);
        path[0] = USDT;
        path[1] = address(this);
        IERC20(USDT).approve(address(pancakeRouter), usdtNeeded);

        try
            pancakeRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                usdtNeeded,
                0,
                path,
                attributableToBuyBackWallet,
                block.timestamp + 30
            )
        {
            emit Buyback(buyBackWallet, usdtNeeded, buyAmount);
        } catch {
            
        }
        swapping = false;
    }




    function _getUSDTRequired(uint256 amountOut) internal view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = USDT;
        path[1] = address(this);

        try pancakeRouter.getAmountsIn(amountOut, path) returns (
            uint256[] memory amounts
        ) {
            return amounts[0];
        } catch {
            return 0;
        }
    }

}