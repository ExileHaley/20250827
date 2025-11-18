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
}

interface IPancakePair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

}


contract X101 is ERC20, Ownable {
    IPancakeRouter02 public pancakeRouter = IPancakeRouter02(0x1F7CdA03D18834C8328cA259AbE57Bf33c46647c);
    address public constant ADX = 0xaF3A1f455D37CC960B359686a016193F72755510;
    address public pancakePair;

    uint256 public constant SELL_TAX_RATE = 20;   // 20%
    uint256 public constant DEL_FEE_RATE = 5;

    mapping(address => bool) public allowlist;
    address public initialRecipient;
    address public sellFee;


    constructor(
        address _initialRecipient,
        address _sellFee
    ) ERC20("X101", "X101") Ownable(msg.sender) {
        initialRecipient = _initialRecipient;
        sellFee = _sellFee;
        pancakePair = IPancakeFactory(pancakeRouter.factory())
            .createPair(address(this), ADX);

        _mint(_initialRecipient, 1_010_000 ether);

        setAllowlist(_initialRecipient, true);
        setAllowlist(_sellFee, true);
        require(address(this) > ADX, "DEPLOY_ERROR.");
    }

    function setAllowlist(address addr, bool isAllow) public onlyOwner {
        require(addr != address(0), "INVALID_ADDRESS.");
        allowlist[addr] = isAllow;
    }

    function setSellFee(address _sellFee) external onlyOwner{
        require(_sellFee != address(0), "INVALID_ADDRESS.");
        sellFee = _sellFee;
    }

    function _update(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {

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

        // addLiquidity user=>pair
        {
            (bool isAdd, ) = _isAddLiquidityV2();
            if (isAdd && to == pancakePair) {
                super._update(from, to, amount);
                return;
            }
        }

        // removeLiquidity pair=>user
        {
            (bool isDel,, ) = _isDelLiquidityV2();
            if (isDel && from == pancakePair) {
                uint256 fee = (amount * DEL_FEE_RATE) / 100;
                uint256 sendAmount = amount - fee;
                
                super._update(from, initialRecipient, fee);
                super._update(from, to, sendAmount);
                return;
            }
        }

        // buy
        if (from == pancakePair) {
            revert("Buy disabled");
        }

        // sell
        if (to == pancakePair) {
            uint256 fee = (amount * SELL_TAX_RATE) / 100;
            uint256 sendAmount = amount - fee;
            super._update(from, sellFee, fee);
            super._update(from, to, sendAmount);
            return;
        }

        // normal transfer
        revert("Transfers disabled");
    }


    function _isAddLiquidityV2()internal view returns(bool ldxAdd, uint256 otherAmount){

        address token0 = IPancakePair(address(pancakePair)).token0();
        (uint r0,,) = IPancakePair(address(pancakePair)).getReserves();
        uint bal0 = IERC20(token0).balanceOf(address(pancakePair));
        if( token0 != address(this) ){
			if( bal0 > r0){
               
				otherAmount = bal0 - r0;
				ldxAdd = otherAmount > 10**15;
			}
		}
    }
	
	function _isDelLiquidityV2()internal view returns(bool ldxDel, bool bot, uint256 otherAmount){

        address token0 = IPancakePair(address(pancakePair)).token0();
        (uint reserves0,,) = IPancakePair(address(pancakePair)).getReserves();
        uint amount = IERC20(token0).balanceOf(address(pancakePair));
		if(token0 != address(this)){
			if(reserves0 > amount){
				otherAmount = reserves0 - amount;
				ldxDel = otherAmount > 10**10;
			}else{
				bot = reserves0 == amount;
			}
		}
    }
}
