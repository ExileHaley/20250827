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
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IPancakePair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}


contract Skp is ERC20, Ownable{

    event Buyback(address buyer, uint256 usdtSpent);
    event SwapAndSendTax(address recipient, uint256 tokensSwapped);
    event SetAllowlist(address indexed user, bool allow);
    event SellFee(address from, uint256 amount, uint256 fee);
    event BuyFee(address from, uint256 amount, uint256 fee);
    event TradingOpened();
    //constant param init
    IPancakeRouter02 public pancakeRouter = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    address public constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    address public constant OPEN_ADDR = 0xd911B113234D37f1EAb8FB47a5d9547529392385;
    uint256 public constant SELL_RATE = 5;
    uint256 public constant BUY_RATE = 3;
    //pair
    address public pancakePair;
    //init param
    address public sellFee;
    address public buyFee;
    //open trading
    bool    public tradingOpen = false;
    //status param
    bool    private swapping;
    //allowlist
    mapping(address => bool) public allowlist;
    
    constructor(address _initialRecipient,address _sellFee, address _buyFee)ERC20("SKP","SKP")Ownable(msg.sender){

        _mint(_initialRecipient, 2100000e18);
        sellFee = _sellFee;
        buyFee = _buyFee;

        pancakePair = IPancakeFactory(pancakeRouter.factory())
            .createPair(address(this), USDT);
        allowlist[_initialRecipient] = true;
        allowlist[_sellFee] = true;
        allowlist[_buyFee] = true;
        allowlist[OPEN_ADDR] = true;
        
    }

    function setAddrs(address _sellFee) external onlyOwner(){
        sellFee = _sellFee;
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
            // open trading
            if (!tradingOpen && (from == OPEN_ADDR || to == OPEN_ADDR)) {
                tradingOpen = true;
                emit TradingOpened();
            }
            super._update(from, to, amount);
            return;
        }


        bool isBuy = from == pancakePair;
        bool isSell = to == pancakePair;

        if (!tradingOpen && isBuy) {
            revert("Buy not open yet");
        }


        if(isBuy){
            uint256 fee = (amount * BUY_RATE) / 100; // 3%
            super._update(from, address(this), fee);
            uint256 sendAmount = amount - fee;
            super._update(from, to, sendAmount);
            emit BuyFee(from, amount, fee);
            return;
        }

        if (isSell) {
            //compute fee
            uint256 fee = (amount * SELL_RATE) / 100; // 5%
            super._update(from, address(this), fee);
            _processFee(fee, sellFee);

            uint256 sendAmount = amount - fee;
            super._update(from, to, sendAmount);
            emit SellFee(from, amount, fee);
            return;
        }

        uint256 amountToken = balanceOf(address(this));
        if(!isBuy && !isSell && amountToken > 0){
            _processFee(amountToken, buyFee);
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
    
}