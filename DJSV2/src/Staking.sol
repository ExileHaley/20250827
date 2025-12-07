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

interface IStakingV1 {
    function serInfo(address user) 
        external 
        view 
        returns (
            address recommender, 
            uint256 staking, 
            uint256 performance, 
            uint256 referralNum
        );
}

interface INode {
    function updateFarm(uint256 amount) external;
}

contract Staking is Initializable, OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuard{
    event Referral(address recommender,address referred);
    event Staked(address user, uint256 amount);

    enum Level {V0, V1, V2, V3, V4, V5, SHARE}
    IUniswapV2Router02 public pancakeRouter = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    address public constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    uint256 public constant MAX_REFERRAL_DEPTH = 1000;
    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address public stakingV1;
    address public node;
    address public token;
    address public subToken;
    address public initialCode;
    address public admin;

    struct User{
        address recommender;
        Level   level;
        uint8   multiple;
        uint256 stakingUsdt;
        uint256 referralAward;
        uint256 performance;
        uint256 referralNum;
        uint256 subCoinQuota;
        uint256 extracted;
        bool    isMigration;
    }

    mapping(address => User) public userInfo;
    mapping(address => address[]) public directReferrals;
    mapping(address => bool) public isAddDirectReferrals;
    uint256 public totalPerformance;
    bool    public pause;

    receive() external payable {
        revert("NO_DIRECT_SEND");
    }

    // Authorize contract upgrades only by the owner
    function _authorizeUpgrade(address newImplementation) internal view override onlyOwner(){}

    function initialize(
        address _admin,
        address _initialCode
    ) public initializer {
        __Ownable_init(_msgSender());
        admin = _admin;
        initialCode = _initialCode;
    }

    modifier Pause() {
        require(!pause, "PAUSE_RECHARGE.");
        _;
    }

    function setPause(bool isPause) external onlyOwner{
        pause = isPause;
    }

    function migrationReferral(address _user) external nonReentrant Pause{
        User storage user = userInfo[_user];
        require(!user.isMigration,"ALREADY_MIGRATEED.");
        (address recommender,,,) = IStakingV1(stakingV1).serInfo(_user);
        require(recommender != address(0), "NON_MIGRATING.");
        user.recommender = recommender;
        user.isMigration = true;
    }

    function whetherNeedMigrate(address _user) public view returns(bool){
        (address recommender,,,) = IStakingV1(stakingV1).serInfo(_user);
        return (!userInfo[_user].isMigration && recommender != address(0));
    }

    function referral(address recommender) external nonReentrant Pause{
        
        require(!whetherNeedMigrate(msg.sender),"NEED_MIGRATE.");
        require(recommender != address(0),"ZERO_ADDRESS.");
        require(recommender != msg.sender,"INVALID_RECOMMENDER.");
        if(recommender != initialCode) require(userInfo[recommender].recommender != address(0) && userInfo[recommender].stakingUsdt > 0,"RECOMMENDATION_IS_REQUIRED_REFERRAL.");
        require(userInfo[msg.sender].recommender == address(0),"INVITER_ALREADY_EXISTS.");
        userInfo[msg.sender].recommender = recommender;
        //有效入金再算作直推
        // directReferrals[recommender].push(msg.sender);
        // _processReferralNumber(msg.sender);
        emit Referral(recommender, msg.sender);
    }

    function staking(uint256 amount) external nonReentrant Pause{
        User storage u = userInfo[msg.sender];
        require(u.recommender != address(0), "RECOMMENDATION_IS_REQUIRED_STAKING.");
        TransferHelper.safeTransferFrom(USDT, msg.sender, address(this), amount);
        //node分红
        uint256 toNodeAmount = amount * 1 / 100;
        TransferHelper.safeTransfer(USDT, node, toNodeAmount);
        INode(node).updateFarm(toNodeAmount);
        //sub coin 销毁
        uint256 toBurnSubCoin = amount * 1 / 100;
        _swap(USDT, subToken, toBurnSubCoin);
        uint256 burnSubCoinAmount = IERC20(subToken).balanceOf(address(this));
        TransferHelper.safeTransfer(subToken, DEAD, burnSubCoinAmount);

        //添加流动性
        uint256 toAddLiquidty = amount - toNodeAmount - toBurnSubCoin;
        uint256 onehalf = toAddLiquidty / 2;
        uint256 balanceTokenBeforeSwap = IERC20(token).balanceOf(address(this));
        _swap(USDT, token, onehalf);
        uint256 balanceTokenAfterSwap = IERC20(token).balanceOf(address(this));
        _addLiquidity(toAddLiquidty - onehalf, balanceTokenAfterSwap - balanceTokenBeforeSwap);
        
        //更新用户信息
        u.stakingUsdt += amount;
        if(u.stakingUsdt > 3000e18) u.multiple = 3;
        else u.multiple = 2;

        //更新理财总业绩
        totalPerformance += amount;

        //更新上级邀请人信息
        _processAll(msg.sender, amount);
    }

    function swapSubToken(uint256 amountUsdt) external{
        User storage u = userInfo[msg.sender];
        require(amountUsdt <= u.subCoinQuota, "Insufficient quota.");
        uint256 beforeSwap = IERC20(subToken).balanceOf(address(this));
        _swap(USDT, subToken, amountUsdt);
        uint256 afterSwap = IERC20(subToken).balanceOf(address(this));
        TransferHelper.safeTransfer(subToken, msg.sender, afterSwap - beforeSwap);
        u.subCoinQuota -= amountUsdt;
    }

    function withdraw(uint256 amount) external nonReentrant Pause{

    }

    function getStakingAward(address user) external view returns(uint256){}

    function getShareLevelAward(address user) external view returns(uint256){}


    /*==============================================================================
    ================================================================================
    ================================================================================
    ================================================================================
    ================================================================================
    =========================== utils func list ====================================
    ================================================================================
    ================================================================================
    ================================================================================
    ================================================================================**/

    function _swap(address _fromToken, address _toToken, uint256 _fromAmount) private{
        // if (fromAmount == 0) return ;
        address[] memory path = new address[](2);
        path[0] = _fromToken;
        path[1] = _toToken;
        IERC20(_fromToken).approve(address(pancakeRouter), _fromAmount);
        pancakeRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _fromAmount,
            0, 
            path,
            address(this),
            block.timestamp + 30
        );
    }

    function _addLiquidity(uint256 amountUsdt, uint256 amountToken) private returns(uint256){
        IERC20(USDT).approve(address(pancakeRouter), amountUsdt);
        IERC20(token).approve(address(pancakeRouter), amountToken);
        (,,uint liquidity) = pancakeRouter.addLiquidity(
            USDT,
            token,
            amountUsdt,
            amountToken,
            0,
            0,
            address(this),
            block.timestamp + 10
        );
        return liquidity;
    }

    // recommender
    //通过recommender向上查找，level V1/V2/V3/V4/V5，对应每个级别的奖励是_amount的10%
    //（1）如果user查找到了第一个V1给10%，继续向上查找如果还碰到V1则不给，给过的同级别略过
    //（2）通过user和user的recommender不停向上查找，直到recommender是0地址
    //（2）这过程中间可能50%在recommender地址后仍旧没有消耗完，这直接将剩余的百分比累加给initialCode

    //处理推荐人升级
    //通过recommender向上查找
    //(1)v1(directReferrals.length>= 3 && performance >= 10000e18)
    //(2)v2(directReferrals.length>= 4 && performance >= 50000e18)
    //(3)v3(directReferrals.length>= 5 && performance >= 200000e18)
    //(4)v4(directReferrals.length>= 7 && performance >= 800000e18)
    //(5)v5(directReferrals.length>= 9 && performance >= 3000000e18)
    //(5)SHARE(directReferrals中两个地址达到V5级别)
    function _processAll(address user, uint256 amount) private {

        address current = userInfo[user].recommender;
        uint256 depth = 0;

        // 用于 ReferralAward 逻辑
        bool[6] memory hasRewarded; 
        uint256 totalRate = 50; // 总共 50% 奖励（10% × 5 个等级）
        
        while (current != address(0) && depth < MAX_REFERRAL_DEPTH) {
            User storage cu = userInfo[current];

            // -------------------------------
            // A. 第一层，添加 directReferrals（只添加一次）
            // -------------------------------
            if (depth == 0 && !isAddDirectReferrals[user]) {
                directReferrals[current].push(user);
                isAddDirectReferrals[user] = true;
            }

            // -------------------------------
            // B. 所有层级都累加人数
            // -------------------------------
            cu.referralNum += 1;

            // -------------------------------
            // C. 所有层级累加 performance
            // -------------------------------
            cu.performance += amount;

            // -------------------------------
            // D. 升级等级（含 subCoinQuota）
            // -------------------------------
            _upgradeLevel(current);

            // -------------------------------
            // E. 发放奖励
            // -------------------------------
            Level lv = cu.level;

            if (lv != Level.SHARE) {
                uint256 idx = uint256(lv);
                if (!hasRewarded[idx]) {
                    uint256 reward = (amount * 10) / 100;
                    cu.referralAward += reward;
                    hasRewarded[idx] = true;
                    totalRate -= 10;
                }
            }

            // 如果达到 SHARE 等级，奖励不再发，但业绩仍可累加和升级
            // current = cu.recommender; 会继续向上循环

            current = cu.recommender;
            depth++;
        }

        // -------------------------------
        // F. 剩余奖励发给 initialCode
        // -------------------------------
        if (totalRate > 0) {
            uint256 remainReward = (amount * totalRate) / 100;
            userInfo[initialCode].referralAward += remainReward;
        }

    }




    function _upgradeLevel(address user) internal {
        User storage u = userInfo[user];

        uint256 referrals = u.referralNum;
        uint256 perf = u.performance;

        Level lv = u.level;

        // -------------------------
        // V0 → V1
        // -------------------------
        if (lv == Level.V0) {
            if (referrals >= 3 && perf >= 10000e18) {
                u.level = Level.V1;
                u.subCoinQuota += 100e18;
            }

        // -------------------------
        // V1 → V2
        // -------------------------
        } else if (lv == Level.V1) {
            if (referrals >= 4 && perf >= 50000e18) {
                u.level = Level.V2;
                u.subCoinQuota += 300e18;
            }

        // -------------------------
        // V2 → V3
        // -------------------------
        } else if (lv == Level.V2) {
            if (referrals >= 5 && perf >= 200000e18) {
                u.level = Level.V3;
                u.subCoinQuota += 500e18;
            }

        // -------------------------
        // V3 → V4
        // -------------------------
        } else if (lv == Level.V3) {
            if (referrals >= 7 && perf >= 800000e18) {
                u.level = Level.V4;
                u.subCoinQuota += 1000e18;
            }

        // -------------------------
        // V4 → V5
        // -------------------------
        } else if (lv == Level.V4) {
            if (referrals >= 9 && perf >= 3000000e18) {
                u.level = Level.V5;
                u.subCoinQuota += 3000e18;
            }

        // -------------------------
        // V5 → SHARE
        // SHARE 条件：直推中至少 2 人达到 V5
        // -------------------------
        } else if (lv == Level.V5) {

            uint256 countV5 = 0;
            address[] memory directs = directReferrals[user];

            for (uint256 i = 0; i < directs.length; i++) {
                if (userInfo[directs[i]].level == Level.V5) {
                    countV5++;
                    if (countV5 >= 2) break;
                }
            }

            if (countV5 >= 2) {
                u.level = Level.SHARE;
                // 默认 SHARE 不给配额，如需可加
                // u.subCoinQuota += ???;
            }
        }
    }

    function removeLiquidity(uint256 amountUsdt) internal returns(uint256 gotUsdt) {
        address pair = IUniswapV2Factory(pancakeRouter.factory()).getPair(USDT, token);
        require(pair != address(0), "PAIR_NOT_EXISTS");

        uint256 totalLP = IERC20(pair).balanceOf(address(this));
        require(totalLP > 0, "NO_LP");

        // 读取储备量
        (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(pair).getReserves();
        (uint112 reserveUSDT, uint112 reserveTOKEN) = USDT < token 
            ? (reserve0, reserve1) 
            : (reserve1, reserve0);

        // 计算 1 LP 的价值（粗略计算）
        uint256 usdtPerLP = uint256(reserveUSDT) * 1e18 / totalLP;

        uint256 tokenPerLP = uint256(reserveTOKEN) * 1e18 / totalLP;

        // 用 swap 预估 token 价值
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = USDT;

        uint256[] memory out = pancakeRouter.getAmountsOut(tokenPerLP, path);
        uint256 tokenUsdtValue = out[1]; // 多少 USDT

        // 每 LP 总价值
        uint256 lpValue = usdtPerLP + tokenUsdtValue;

        // 需要的 LP 数量 = 目标 USDT / 1LP 的价值
        uint256 lpNeeded = amountUsdt * 1e18 / lpValue;

        require(lpNeeded <= totalLP, "INSUFFICIENT_LP");

        // approve
        IERC20(pair).approve(address(pancakeRouter), lpNeeded);

        // remove
        (uint256 amountUSDTFromLP, uint256 amountTOKENFromLP) = pancakeRouter.removeLiquidity(
            USDT,
            token,
            lpNeeded,
            0,
            0,
            address(this),
            block.timestamp + 30
        );

        // sell TOKEN → USDT
        uint256 before = IERC20(USDT).balanceOf(address(this));

        IERC20(token).approve(address(pancakeRouter), amountTOKENFromLP);
        pancakeRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountTOKENFromLP,
            0,
            path,
            address(this),
            block.timestamp + 30
        );

        uint256 afterBalance = IERC20(USDT).balanceOf(address(this));
        uint256 tokenToUsdt = afterBalance - before;

        gotUsdt = amountUSDTFromLP + tokenToUsdt;
    }


}
