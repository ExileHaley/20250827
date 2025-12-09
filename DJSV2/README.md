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
}
```
1.代币买卖5%，买的分3%和2%，3%给到节点认购分红(前1000个和后1000个)，有白名单，有盈利税35%，盈利税其中10%分给节点，20%给钱包地址，5%留存到钱钱包手动买入子币销毁，每天底池销毁0.3%
2.三四入金100个，1个去买子币销毁，1个分给节点，98进底池强制更新价格
3.级别可以设置、利润比例可以设置，给指定用户充值管理功能

4.提现5u手续费，买子币销毁
