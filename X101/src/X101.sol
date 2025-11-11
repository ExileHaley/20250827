// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

interface IPancakeFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IPancakeRouter02 {
    function factory() external pure returns (address);
}

contract X101 is ERC20, Ownable {
    IPancakeRouter02 public pancakeRouter = IPancakeRouter02(0x1F7CdA03D18834C8328cA259AbE57Bf33c46647c);
    address public constant ADX = 0xaF3A1f455D37CC960B359686a016193F72755510;
    address public pancakePair;

    uint256 public constant SELL_TAX_RATE = 20;   // 20%

    mapping(address => bool) public allowlist;

    address public sellFee;

    constructor(
        address _initialRecipient,
        address _sellFee
    ) ERC20("X101", "X101") Ownable(msg.sender) {
        sellFee = _sellFee;
        // 创建交易对
        pancakePair = IPancakeFactory(pancakeRouter.factory())
            .createPair(address(this), ADX);
        // 铸造初始供应
        _mint(_initialRecipient, 1_010_000 ether);

        address[] memory addrs = new address[](2);
        addrs[0] = _initialRecipient;
        addrs[1] = _sellFee;
        setAllowlist(addrs, true);
    }

    // 批量设置白名单
    function setAllowlist(address[] memory addrs, bool isAllow) public onlyOwner {
        for (uint256 i = 0; i < addrs.length; i++) {
            allowlist[addrs[i]] = isAllow;
        }
    }

    function setSellFee(address _sellFee) external onlyOwner{
        sellFee = _sellFee;
    }

    function _update(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        // 铸造或销毁情况不加税
        if (from == address(0) || to == address(0)) {
            super._update(from, to, amount);
            return;
        }

        // 白名单自由交易
        if (allowlist[from] || allowlist[to]) {
            super._update(from, to, amount);
            return;
        }

        // 买入（从交易对买）：to 不是交易对，from 是交易对
        if (from == pancakePair) {
            revert("Buy disabled");
        }

        // 卖出（往交易对卖）：to 是交易对
        if (to == pancakePair) {
            uint256 fee = (amount * SELL_TAX_RATE) / 100;
            uint256 sendAmount = amount - fee;
            super._update(from, sellFee, fee);
            super._update(from, to, sendAmount);
            return;
        }

        // 普通转账
        revert("Transfers disabled");
    }
}
