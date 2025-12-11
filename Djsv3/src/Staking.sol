// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {TransferHelper} from "./libraries/TransferHelper.sol";
import {ReentrancyGuard} from "./libraries/ReentrancyGuard.sol";
import {Errors} from "./libraries/Errors.sol";
import {Process} from "./libraries/Process.sol";
import {IUniswapV2Router02} from "./interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Factory} from "./interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "./interfaces/IUniswapV2Pair.sol";
import {ILiquidity} from "./interfaces/ILiquidity.sol";


// interface ILiquidity{
//     function swapForSubTokenToUser(address to, uint256 amountUSDT) external;
//     function swapForSubTokenToBurn(uint256 amountUSDT) external;
//     function addLiquidity(uint256 amountUSDT) external;
//     function acquireSpecifiedUsdt(address to, uint256 amountUSDT) external;
// }

interface IDjsv1 {
    function userInfo(address user) 
        external 
        view 
        returns (
            address recommender, 
            uint256 staking, 
            uint256 performance, 
            uint256 referralNum
        );
    function getUserInfo(address user) 
        external 
        view 
        returns (
            address recommender, 
            uint256 staking, 
            uint256 performance, 
            uint256 referralNum, 
            address[] memory referrals
        );
}

interface INode {
    function updateFarm(uint256 amount) external;
}

contract Staking is Initializable, OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuard{
    event Referrals(address recommender,address referred);
    event Staked(address user, uint256 amount);
    event Claimed(address user, uint256 amount);

    IUniswapV2Router02 public pancakeRouter = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    address public constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;
    uint256 public constant MAX_REFERRAL_DEPTH = 1000;
    
    address public admin;
    address public initialCode;
    address public djsv1;
    address public node;
    address public liquidityManager;
    
    mapping(address => Process.User) public userInfo;
    mapping(address => Process.Referral) public referralInfo;
    mapping(address => Process.Record[]) public awardRecords;

    mapping(address => address[]) public directReferrals;
    mapping(address => bool) public isAddDirectReferrals;

    mapping(Process.Level => uint256) public subCoinQuotas;
    
    uint256 public totalStakedUsdt;
    bool    public pause;

    //理财收益计算参数
    uint256 public perSecondStakedAeward;
    uint256   public decimals;

    //share等级收益计算变量
    uint256 public lastShareAwardTime;
    uint256 public perSharePerformanceAward;
    uint256 public totalSharePerformance;
    uint256 public shareRate;
    

    //新增一个方法判断当前用户质押的stakingUsdt是否有效理财
    //SHARE分红按照各自的邀请业绩来计算
    //新增一个全局变量动态更新有效总质押量
    

    receive() external payable {
        revert("NO_DIRECT_SEND");
    }

    // Authorize contract upgrades only by the owner
    function _authorizeUpgrade(address newImplementation) internal view override onlyOwner(){}

    function initialize(
        address _admin,
        address _initialCode,
        address _djsv1,
        address _node,
        address _liquidity
    ) public initializer {
        __Ownable_init(_msgSender());
        admin = _admin;
        initialCode = _initialCode;
        djsv1 = _djsv1;
        node = _node;
        liquidityManager = _liquidity;
        decimals = 1e10;
        perSecondStakedAeward = uint256(12e18 * decimals / 1000e18 / 86400); //这里得计算一下每秒奖励的代币数
        shareRate = 10; //share 奖励比例10%
        subCoinQuotas[Process.Level.V1] = 100e18;
        subCoinQuotas[Process.Level.V2] = 300e18;
        subCoinQuotas[Process.Level.V3] = 500e18;
        subCoinQuotas[Process.Level.V4] = 1000e18;
        subCoinQuotas[Process.Level.V5] = 3000e18;
    }

    modifier Pause() {
        require(!pause, "PAUSE_RECHARGE.");
        _;
    }

    function setPause(bool isPause) external onlyOwner{
        pause = isPause;
    }

    function migrationReferral(address user) external nonReentrant Pause{
        Process.Referral storage r = referralInfo[user];
        if(r.isMigration) revert Errors.AlreadyMigrated();
        (address recommender,,,) = IDjsv1(djsv1).userInfo(user);
        if(recommender == address(0)) revert Errors.NoMigrationRequired();
        r.recommender = recommender;
        r.isMigration = true;
    }

    function whetherNeedMigrate(address user) public view returns(bool){
        (address v1Recommender,,,) = IDjsv1(djsv1).userInfo(user);
        // 需要迁移的条件：v1 有 recommender 且 新系统未标记为已迁移
        return (v1Recommender != address(0) && !referralInfo[user].isMigration);
    }

    function referral(address recommender) external nonReentrant Pause{
        //需要映射
        if(whetherNeedMigrate(msg.sender)) revert Errors.NeedMigrate();
        if(recommender == address(0)) revert Errors.ZeroAddress();
        if(recommender == msg.sender) revert Errors.InvalidRecommender();
        if(recommender != initialCode) {
            require(referralInfo[recommender].recommender != address(0) && userInfo[recommender].stakingUsdt > 0,"RECOMMENDATION_IS_REQUIRED_REFERRAL.");
        }
        if(referralInfo[msg.sender].recommender != address(0)) revert Errors.InviterExists();
        referralInfo[msg.sender].recommender = recommender;
        emit Referrals(recommender, msg.sender);
    }

    function stake(uint256 amountUSDT) external nonReentrant Pause{
        Process.User storage u = userInfo[msg.sender];
        Process.Referral storage r = referralInfo[msg.sender];
        if(r.recommender == address(0)) revert Errors.NotRequiredReferral();
        if(amountUSDT < 100e18) revert Errors.AmountTooLow();
        //分两次转账，给node(1%)/liquidity(99%)
        uint256 amountToNode = amountUSDT * 1 / 100;
        uint256 amountToBurnSubToken = amountUSDT * 1 / 100;
        TransferHelper.safeTransferFrom(USDT, msg.sender, liquidityManager, amountUSDT - amountToNode);
        TransferHelper.safeTransferFrom(USDT, msg.sender, node, amountToNode);
        //处理node分红1%，子币销毁1%，添加流动性98%
        ILiquidity(liquidityManager).swapForSubTokenToBurn(amountToBurnSubToken);

        if(node != address(0)) INode(node).updateFarm(amountToNode);

        ILiquidity(liquidityManager).addLiquidity(amountUSDT - amountToNode - amountToBurnSubToken);

        //先计算之前的收益给 pendingProfit，计算参数包括理财收益
        //1.用户总收益不能大雨stakingUsdt * multiple
        //2.stakingUsdt * multiple <= 理财收益 + referralAward + extracted + pendingProfit + 
        uint256 reward = getUserAward(msg.sender);
        if(reward > 0) u.pendingProfit += reward;
        //更新stakingUsdt
        u.stakingUsdt += amountUSDT;
        //更新质押时间stakingTime
        u.stakingTime = block.timestamp;
        //根据数量设置倍数 multiple
        uint256 newMultiple = u.stakingUsdt > 3000e18 ? 3 : 2;
        if (u.multiple != newMultiple) {
            u.multiple = newMultiple;
        }
        //更新总质押totalStakedUsdt
        totalStakedUsdt += amountUSDT;
        

        uint256 sharePerformance = processLayer(msg.sender, amountUSDT);
        if(sharePerformance > 0) totalSharePerformance += sharePerformance;
        updateShareFram();
        
        if(r.level == Process.Level.SHARE) r.shareAwardDebt = perSharePerformanceAward * r.performance;
        if(!isAddDirectReferrals[msg.sender]){
            directReferrals[r.recommender].push(msg.sender);
            isAddDirectReferrals[msg.sender] = true;
        }
        emit Staked(msg.sender, amountUSDT);
    }

    //计算用户当前真实可提取收益
    //1.收益包括质押收益 + 邀请收益 + share等级收益 = 总的毛收益
    //2.总毛收益 + 已经提取的收益 必须要小于等于u.stakingUsdt * u.multiple
    //3.通过2计算差额，也就是说用户提取+未提取的收益不能大于u.stakingUsdt * u.multiple
    function getUserAward(address user) public view returns(uint256){
        Process.User memory u = userInfo[user];
        if (u.stakingUsdt == 0) return 0;

        // 1. 计算当前动态质押收益（还没结算进 pendingProfit 部分）
        uint256 delta = block.timestamp - u.stakingTime;
        uint256 stakeAward = u.stakingUsdt * delta * perSecondStakedAeward / decimals;

        // 2. SHARE 等级收益（此部分可动态计算，不累加进 pendingProfit）
        uint256 shareAward = getShareLevelAward(user);

        // 3. 用户当前总未提取收益
        uint256 totalAward = u.pendingProfit + stakeAward + shareAward;

        // 4. 收益上限 = stakingUsdt * multiple
        uint256 maxAward = u.stakingUsdt * u.multiple;

        // 5. 用户剩余额度
        if (u.extracted >= maxAward) return 0;
        uint256 remaining = maxAward - u.extracted;

        // 6. 返回最小值
        if (totalAward > remaining) return remaining;
        return totalAward;
    }

    //计算Share等级的收益
    //1.每次claim时更新perSharePerformanceAward，用totalStakedUsdt * 时间间隔 * 每个质押收益 / 总的share等级业绩
    //2.计算动态收益，按照上述方式计算没更新的当前时间段内的收益，动态计算不依赖更新
    //3.把两部分的收益加起来就等于总的Share等级收益
    function getShareLevelAward(address user) public view returns(uint256){
        Process.Referral memory r = referralInfo[user];
        if (r.performance == 0 || totalSharePerformance == 0) return 0;

        // 累计奖励
        uint256 acc = perSharePerformanceAward;

        // 动态奖励（未更新到 perSharePerformanceAward 的部分）
        uint256 delta = block.timestamp - lastShareAwardTime;
        if (delta > 0) {
            uint256 totalShareAward = totalStakedUsdt * delta * perSecondStakedAeward * shareRate / 100;
            acc += totalShareAward / totalSharePerformance;
        }

        uint256 reward = r.performance * acc / decimals;

        // 扣除用户已结算债务
        if (reward <= r.shareAwardDebt) return 0;
        return reward - r.shareAwardDebt;
    }




    function updateShareFram() internal {
        uint256 delta = block.timestamp - lastShareAwardTime;
        if (delta == 0 || totalSharePerformance == 0) {
            lastShareAwardTime = block.timestamp;
            return;
        }

        uint256 totalShareAward =
            totalStakedUsdt * delta * perSecondStakedAeward * shareRate / 100;

        perSharePerformanceAward += totalShareAward / totalSharePerformance;
        lastShareAwardTime = block.timestamp;
    }

    function claim(uint256 amount) external nonReentrant {
        Process.User storage u = userInfo[msg.sender];
        if (u.stakingUsdt == 0) revert Errors.NoStake();

        // 1. 更新 SHARE 奖励
        updateShareFram();

        // 2. 获取用户可提取总收益
        uint256 totalAward = getUserAward(msg.sender);
        if (totalAward == 0) revert Errors.NoReward();

        // 3. 限制用户提取额度
        uint256 claimAmount = amount > totalAward ? totalAward : amount;

        // 4. 优先扣减 pendingProfit
        if(u.pendingProfit >= claimAmount){
            u.pendingProfit -= claimAmount;
        } else {
            u.pendingProfit = 0;
            // 剩余从动态质押收益 + SHARE收益扣减，直接通过 extracted 处理
        }

        // 5. 更新已提取金额
        u.extracted += claimAmount;

        // 6. 转账 USDT 给用户
        ILiquidity(liquidityManager).acquireSpecifiedUsdt(msg.sender, claimAmount);
        if(referralInfo[msg.sender].level == Process.Level.SHARE) referralInfo[msg.sender].shareAwardDebt = perSharePerformanceAward * referralInfo[msg.sender].performance;
        emit Claimed(msg.sender, claimAmount);
    }



    function processLayer(
        address user,
        uint256 amount
    ) internal returns(uint256 sharePerformance) {
        address current = referralInfo[user].recommender;
        bool[6] memory hasRewarded;
        uint256 totalRate = 50;
        sharePerformance = 0;

        while(current != address(0)){

            Process.Referral storage r = referralInfo[current];
            r.referralNum += 1;
            r.performance += amount;

            // 计算直推 V5 数量
            uint256 directV5 = 0;
            for(uint i=0; i<directReferrals[current].length; i++){
                if(referralInfo[directReferrals[current][i]].level == Process.Level.V5) directV5++;
            }

            

            // 发放奖励
            (uint256 reward, bool updated) = Process.calcReferralReward(r.level, hasRewarded, amount);
            if(updated){
                r.referralAward += reward;
                awardRecords[current].push(Process.Record(user, reward, block.timestamp));
                hasRewarded[uint256(r.level)] = true;
                totalRate -= 10;
            }

            // 计算等级升级
            (Process.Level newLevel, uint256 addedShare, bool upgrade) = Process.calcUpgradeLevel(r, directV5);
            r.level = newLevel;
            sharePerformance += addedShare;
            if(upgrade) r.subCoinQuota += subCoinQuotas[newLevel];

            // 累加人数和业绩

            current = r.recommender;
        }

        // 剩余奖励给 initialCode
        if(totalRate > 0){
            referralInfo[initialCode].referralAward += (amount * totalRate)/100;
        }
    }


    function swapSubToken(uint256 amountUSDT) external {
        if(amountUSDT > referralInfo[msg.sender].subCoinQuota) revert Errors.InsufficientQuota();
        TransferHelper.safeTransferFrom(USDT, msg.sender, liquidityManager, amountUSDT);
        ILiquidity(liquidityManager).swapForSubTokenToUser(msg.sender, amountUSDT);
        referralInfo[msg.sender].subCoinQuota -= amountUSDT;
    }

    // 返回用户基础信息 + 当前可提取收益 + Share等级收益
    function getUserInfoBasic(address user) public view returns(
        Process.Level level,
        address recommender,
        uint256 stakingUsdt,
        uint256 multiple,
        uint256 totalAward,
        uint256 shareAward
    ){
        Process.User memory u = userInfo[user];
        Process.Referral memory r = referralInfo[user];

        level = r.level;
        recommender = r.recommender;
        stakingUsdt = u.stakingUsdt;
        multiple = u.multiple;

        // 当前可提取总收益
        totalAward = getUserAward(user);
        // 当前Share等级收益
        shareAward = getShareLevelAward(user);
    }

    // 返回用户邀请/推荐相关信息
    function getUserInfoReferral(address user) external view returns (
        uint256 referralNum,
        uint256 performance,
        uint256 referralAward,
        uint256 subCoinQuota,
        bool    isMigration
    ) {
        Process.Referral memory r = referralInfo[user];

        referralNum = r.referralNum;
        performance = r.performance;
        referralAward = r.referralAward;
        subCoinQuota = r.subCoinQuota;
        isMigration = r.isMigration;
    }

    function getReferralAwardRecords(address user) external view returns(Process.Record[] memory){
        return awardRecords[user];
    }

    function getDirectReferrals(address user) external view returns(address[] memory){
        return directReferrals[user];
    }

}
//累加业绩的时候应该要给totalSharePerformance再加上，条件如果recomm..是SHARE
//增加一个获取奖励记录的方法
//410000000000000000000
//10000000000000000000