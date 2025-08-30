// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

interface IPancakeRouter02 {
    function factory() external pure returns (address);
}

interface IPancakeFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IPancakePair {
    function sync() external;
    function totalSupply() external view returns (uint);
}

contract Snt is ERC20, Ownable {
    IPancakeRouter02 public pancakeRouter = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    address public constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    address public sellFee;
    address public buyFee;
    address public pancakePair;
    uint256 public lastBurnTime;

    uint256 public constant SELL_TAX_RATE = 300;   // 3%
    uint256 public constant BUY_TAX_RATE  = 1000;  // 10%
    uint256 public constant BURN_INTERVAL = 24 hours;
    uint256 public constant BURN_RATE     = 20;    // 0.2%

    bool private _inBurn; 

    constructor(
        address _initialRecipient,
        address _sellFee,
        address _buyFee
    ) ERC20("SNT","SNT") Ownable(msg.sender) {
        uint256 initialSupply = 1777777 ether;
        _mint(_initialRecipient, initialSupply);
        sellFee = _sellFee;
        buyFee = _buyFee;

        pancakePair = IPancakeFactory(pancakeRouter.factory())
            .createPair(address(this), USDT);
    }

    function setFeeRecipient(address _sellFee, address _buyFee) external onlyOwner {
        require(_sellFee != address(0) && _buyFee != address(0), "Error recipient.");
        sellFee = _sellFee;
        buyFee  = _buyFee;
    } 

    function _update(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (lastBurnTime == 0 && pancakePair != address(0)) {
            try IPancakePair(pancakePair).totalSupply() returns (uint256 supply) {
                if (supply > 0) lastBurnTime = block.timestamp;
            } catch {}
        }

        // mint / burn
        if (from == address(0) || to == address(0)) {
            super._update(from, to, amount);
            return;
        }

        uint256 adjustedAmount = (amount / 1e16) * 1e16;
        if (adjustedAmount == 0) return;

        uint256 taxAmount = 0;
        address feeRecipient = address(0);

        if (to == pancakePair && sellFee != address(0)) {
            taxAmount = (adjustedAmount * SELL_TAX_RATE) / 10000;
            feeRecipient = sellFee;
        } else if (from == pancakePair && buyFee != address(0)) {
            taxAmount = (adjustedAmount * BUY_TAX_RATE) / 10000;
            feeRecipient = buyFee;
        }

        if (taxAmount > 0) {
            super._update(from, feeRecipient, taxAmount);
            super._update(from, to, adjustedAmount - taxAmount);
        } else {
            super._update(from, to, adjustedAmount);
        }

        
        if (!_inBurn && from != pancakePair && to != pancakePair) _safeTryBurnFromPair();
        
    }

    function _safeTryBurnFromPair() private {
        if (block.timestamp < lastBurnTime + BURN_INTERVAL || lastBurnTime == 0) return;

        uint256 elapsed = block.timestamp - lastBurnTime;
        uint256 cycles  = elapsed / BURN_INTERVAL;
        uint256 pairBalance = balanceOf(pancakePair);

        if (pairBalance == 0 || cycles == 0) return;

        uint256 burnRate = cycles * BURN_RATE;
        if (burnRate > 5000) burnRate = 5000; 

        uint256 burnAmount = (pairBalance * burnRate) / 10000;
        if (burnAmount == 0) return;

        
        _inBurn = true;
        _forceBurnAndSync(burnAmount, cycles);
        _inBurn = false;
    }

    function _forceBurnAndSync(uint256 burnAmount, uint256 cycles) private {
        _burn(pancakePair, burnAmount);
        lastBurnTime += cycles * BURN_INTERVAL;
        IPancakePair(pancakePair).sync();
    }
}

