// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IPancakeRouter02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}

contract Fact is ERC20, Ownable{
    event TradingOpened();
    event SetAllowlist(address indexed user, bool allow);
    event SetFeeAddresses(address buyFee, address sellFee);

    IPancakeRouter02 public pancakeRouter = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    uint256 public constant TAX_RATE = 30; // 3%
    address public constant OPEN_ADDR = 0x717Cc0E17a361c6fe16dB3238255Cda2d79f5a1A;
    uint256 public constant TAX_DENOMINATOR = 1000;


    address public pancakePair;
    bool    public tradingOpen = false;
    address public buyFee;
    address public sellFee;
    mapping(address => bool) public allowlist;


    constructor(
        address _initialRecipient,
        address _buyFee,
        address _sellFee
    ) ERC20("FACT", "FACT") Ownable(msg.sender) {
        buyFee = _buyFee;
        sellFee = _sellFee;
        pancakePair = IUniswapV2Factory(pancakeRouter.factory())
            .createPair(address(this), pancakeRouter.WETH());
        _mint(_initialRecipient, 100_000_000 ether);
  
        //------- set allow list -------
        setAllowlist(_initialRecipient, true);
        setAllowlist(_buyFee, true);
        setAllowlist(_sellFee, true);
        setAllowlist(OPEN_ADDR, true);
    }

    function setAllowlist(address addr, bool isAllow) public onlyOwner {
        allowlist[addr] = isAllow;
        emit SetAllowlist(addr, isAllow);
    }

    function setFeeAddresses(address _buyFee, address _sellFee) external onlyOwner {
        buyFee = _buyFee;
        sellFee = _sellFee;
        emit SetFeeAddresses(_buyFee, _sellFee);
    }

    function _update(address from, address to, uint256 amount) internal virtual override {
        // ======== 1. mint / burn  ========
        if (from == address(0) || to == address(0)) {
            super._update(from, to, amount);
            return;
        }

        // ======== 2. transaction condtion ========
        bool isBuy = from == pancakePair;  // pair -> user
        bool isSell = to == pancakePair;   // user -> pair

        // ======== 3. allowlist ========
        bool fromAllow = allowlist[from];
        bool toAllow = allowlist[to];

        if (fromAllow || toAllow) {
            // open trading
            if (!tradingOpen && (from == OPEN_ADDR || to == OPEN_ADDR)) {
                tradingOpen = true;
                emit TradingOpened();
            }
            super._update(from, to, amount);
            return;
        }

        // ======== 4. normal trade buy ========
        if (!tradingOpen && isBuy) {
            revert("Buy not open yet");
        }

        // ======== 5. transfer ========
        if (!isBuy && !isSell) {
            super._update(from, to, amount);
            return;
        }

        // ======== 6. transaction fee ========
        uint256 taxAmount = (amount * TAX_RATE) / TAX_DENOMINATOR;
        uint256 receiveAmount = amount - taxAmount;

        address feeReceiver = isBuy ? buyFee : sellFee;

        unchecked {
            super._update(from, feeReceiver, taxAmount);
            super._update(from, to, receiveAmount);
        }
    }

    
}