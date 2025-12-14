// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPancakeFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// interface IPancakePair {
//     function token0() external view returns (address);
//     function token1() external view returns (address);
//     function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
//     function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
// }


contract TDjs is ERC20, Ownable{

    IUniswapV2Router02 public pancakeRouter = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    address public constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;
    uint256 public constant FEE_RATE = 5;

    //pair
    address public pancakePair;
    address public marketing;
    address public nodeDividends;
    address public buyback;

    bool    private swapping;

    mapping(address => bool) public allowlist;


    constructor(address _initialRecipient)ERC20("DJS","DJSC")Ownable(msg.sender){
        _mint(_initialRecipient, 100000e18);
        pancakePair = IPancakeFactory(pancakeRouter.factory())
            .createPair(address(this), USDT);
        allowlist[_initialRecipient] = true;
    }


}