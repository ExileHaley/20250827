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
}

interface IPancakePair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

contract Skp is ERC20, Ownable{
    event SwapAndSendTax(address recipient, uint256 tokensSwapped);
    event SetAllowlist(address indexed user, bool allow);
    event SellFee(address from, uint256 amount, uint256 fee);
    IPancakeRouter02 public pancakeRouter = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    address public constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    uint256 public constant SELL_RATE = 5; // 3%
    address public sellFee;
    address public pancakePair;
    bool    private swapping;
    mapping(address => bool) public allowlist;


    constructor(address _initialRecipient,address _sellFee)ERC20("SKP","SKP")Ownable(msg.sender){

        _mint(_initialRecipient, 2100000e18);
        sellFee = _sellFee;

        pancakePair = IPancakeFactory(pancakeRouter.factory())
            .createPair(address(this), USDT);
        allowlist[_initialRecipient] = true;
        allowlist[_sellFee] = true;
    }

    function setFeeRecipient(address _sellFee) external onlyOwner(){
        sellFee = _sellFee;
    }

    function setAllowlist(address addr, bool isAllow) public onlyOwner {
        allowlist[addr] = isAllow;
        emit SetAllowlist(addr, isAllow);
    }

    function _update(address from, address to, uint256 amount) internal virtual override{
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
            uint256 fee = (amount * SELL_RATE) / 100; // 5%
            uint256 sendAmount = amount - fee;
            super._update(from, address(this), fee);
            super._update(from, to, sendAmount);

            // swap fee to USDT
            _swapToUSDT(fee, sellFee);
            emit SellFee(from, amount, fee);
            return;
        }

        super._update(from, to, amount);

    }

    function _swapToUSDT(uint256 amount, address to) internal{
        if (amount == 0) return ;
        swapping = true;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = USDT;
        
        _approve(address(this), address(pancakeRouter), amount);
        
        try pancakeRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            0, 
            path,
            to,
            block.timestamp + 30
        ) {
            emit SwapAndSendTax(to, amount);
        }catch{}

        swapping = false;
    }


}