### install foundry-rs/forge-std
```shell
$ forge install foundry-rs/forge-std --no-commit --no-git
```
### install openzeppelin-contracts
```shell
$ forge install openzeppelin/openzeppelin-contracts  --no-git
```

### install openzeppelin-contracts-upgradeable
```shell
$ forge install openzeppelin/openzeppelin-contracts-upgradeable  --no-git
```

### deploy wallet
```shell
$ forge script script/Deploy.s.sol -vvv --rpc-url=https://bsc.blockrazor.xyz --broadcast --private-key=[privateKey]
```

### 查看未执行执行nonce
```shell
$ cast nonce [wallet-address] --rpc-url https://bsc.blockrazor.xyz
```

#### 映射钱保持不能入金和提现的状态，批量给地址判断没映射的手动进行映射,给一个状态判断是否进行了映射


#### DJS token address:
#### staking address:


#### staking func list
```solidity


```

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library Errors {
    error ZeroAddress();
    error InvalidRecommender();
    error NeedMigrate();
    error AlreadyMigrated();
    error NoLiquidity();
    error PauseError();
    error InsufficientQuota();
    error InviterExists();
    error PairNotExists();
    error InsufficientLP();
    error NotAuthorized();
    error AmountZero();
    error TransferFailed();
    error NotStarted();
    error ExceededLimit();
    error NotHolder();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library RewardLib {

    enum Level {V0, V1, V2, V3, V4, V5, SHARE}

    struct User {
        address recommender;
        Level level;
        uint8 multiple;
        uint256 stakingUsdt;
        uint256 referralAward;
        uint256 performance;
        uint256 referralNum;
        uint256 subCoinQuota;
        bool isMigration;
    }

    // -----------------------------
    // 升级等级逻辑
    // -----------------------------
    function upgradeLevel(
        mapping(address => User) storage userInfo,
        address user,
        mapping(address => address[]) storage directReferrals
    ) internal {
        User storage u = userInfo[user];
        uint256 referrals = u.referralNum;
        uint256 perf = u.performance;
        Level lv = u.level;

        if (lv == Level.V0 && referrals >=3 && perf >= 10000e18) {
            u.level = Level.V1;
            u.subCoinQuota += 100e18;
        } else if (lv == Level.V1 && referrals >=4 && perf >= 50000e18) {
            u.level = Level.V2;
            u.subCoinQuota += 300e18;
        } else if (lv == Level.V2 && referrals >=5 && perf >= 200000e18) {
            u.level = Level.V3;
            u.subCoinQuota += 500e18;
        } else if (lv == Level.V3 && referrals >=7 && perf >= 800000e18) {
            u.level = Level.V4;
            u.subCoinQuota += 1000e18;
        } else if (lv == Level.V4 && referrals >=9 && perf >= 3000000e18) {
            u.level = Level.V5;
            u.subCoinQuota += 3000e18;
        } else if (lv == Level.V5) {
            // SHARE 条件：直推中至少 2 人达到 V5
            uint256 countV5 = 0;
            address[] memory directs = directReferrals[user];
            for(uint i=0;i<directs.length;i++){
                if(userInfo[directs[i]].level == Level.V5){
                    countV5++;
                    if(countV5 >=2) break;
                }
            }
            if(countV5 >=2){
                u.level = Level.SHARE;
            }
        }
    }

    // -----------------------------
    // 发放推荐奖励
    // -----------------------------
    function processReferral(
        mapping(address => User) storage userInfo,
        mapping(address => address[]) storage directReferrals,
        address initialCode,
        address user,
        uint256 amount
    ) internal {
        address current = userInfo[user].recommender;
        uint256 depth = 0;
        uint256 totalRate = 50; // 总共 50%
        bool[6] memory hasRewarded;

        while(current != address(0) && depth < 1000){
            User storage cu = userInfo[current];
            if(depth == 0 && directReferrals[current].length > 0){
                directReferrals[current].push(user);
            }

            cu.referralNum += 1;
            cu.performance += amount;
            upgradeLevel(userInfo, current, directReferrals);

            uint idx = uint(cu.level);
            if(idx < 6 && !hasRewarded[idx]){
                uint reward = amount * 10 / 100;
                cu.referralAward += reward;
                hasRewarded[idx] = true;
                totalRate -= 10;
            }

            current = cu.recommender;
            depth++;
        }

        if(totalRate > 0){
            userInfo[initialCode].referralAward += amount * totalRate / 100;
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IUniswapV2Router02} from "./interfaces/IUniswapV2Router02.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


library CalcLib {

    // -----------------------------
    // Swap 相关
    // -----------------------------
    function swapExactIn(
        IUniswapV2Router02 router,
        address[] memory path,
        uint256 amountIn,
        address to
    ) internal {
        IERC20(path[0]).approve(address(router), amountIn);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn,
            0,
            path,
            to,
            block.timestamp + 30
        );
    }

    // -----------------------------
    // LP 添加/移除预估
    // -----------------------------
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns(uint amountB) {
        require(amountA > 0, "AmountA zero");
        require(reserveA > 0 && reserveB > 0, "Reserve zero");
        amountB = (amountA * reserveB) / reserveA;
    }

    // -----------------------------
    // 分红计算
    // -----------------------------
    function pendingReward(
        uint256 userAmount,
        uint256 accPerShare
    ) internal pure returns(uint256 reward){
        reward = (userAmount * accPerShare) / 1e18;
    }

    // -----------------------------
    // 盈利税计算
    // -----------------------------
    function calcLpNeeded(
        uint256 reserveUSDT,
        uint256 reserveToken,
        uint256 totalLP,
        uint256 targetUSDT,
        uint256 tokenToUsdt // token per LP 换算成 USDT
    ) internal pure returns(uint256 lpNeeded) {
        uint256 usdtPerLP = reserveUSDT * 1e18 / totalLP;
        uint256 tokenPerLPUsdt = tokenToUsdt; // swap 后的 USDT 价值
        uint256 lpValue = usdtPerLP + tokenPerLPUsdt;
        lpNeeded = targetUSDT * 1e18 / lpValue;
    }

    
}


```
1.代币买卖5%，买的分3%和2%，3%给到节点认购分红(前1000个和后1000个)，有白名单，有盈利税35%，盈利税其中10%分给节点，20%给钱包地址，5%留存到钱钱包手动买入子币销毁，每天底池销毁0.3%
2.三四入金100个，1个去买子币销毁，1个分给节点，98进底池强制更新价格
3.级别可以设置、利润比例可以设置，给指定用户充值管理功能

4.提现5u手续费，买子币销毁
