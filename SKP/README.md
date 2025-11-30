### install foundry-rs/forge-std
```shell
$ forge install foundry-rs/forge-std --no-commit --no-git
```
### install openzeppelin-contracts
```shell
$ forge install openzeppelin/openzeppelin-contracts --no-commit --no-git
```

### install openzeppelin-contracts-upgradeable
```shell
$ forge install openzeppelin/openzeppelin-contracts-upgradeable --no-commit --no-git
```

### deploy wallet
```shell
$ forge script script/Deploy.s.sol -vvv --rpc-url=https://bsc.blockrazor.xyz --broadcast --private-key=[privateKey]
```

#### abi:./out/recharge.sol/recharge.json

```solidity
//单币种充值，token传0地址标识要充值主币，其他地址正常，amount充值的数量，remark标识
function singleRecharge(address token, uint256 amount, string calldata remark) external payable;
//双币种充值，token0/token1如果其中一个为0地址，则表示充值主币，amount0/amount1要与之对应
function multiRecharge(
        address token0,
        uint256 amount0,
        address token1,
        uint256 amount1,
        string calldata remark
    ) external payable；
```

### SKP token address:0x3E8A6DB97b0390498D85447b396462883188607C
### pancake pair address:0x7B98ef76a4AE1F1B31Af561396a56C675ED5b20d
### recharge address:0x72A2d9FD983b131D81Fa726fEf74857021b68e0a



代币名称:SKP 
代币符号：SKP 
代币总量：210万枚 
代币接收地址：0xD4360fAE9a810Be17b5fC1edF12849675996f712 
卖出滑点5%地址：0x73832D01364c48e4b6C49B9ECBF07aB92852B67c 分配USDT 
 
 
支付: 
入金20%地址：0x5d8d24dc99ae142b432acb3bc509758578900296      
入金30%地址：0xec94798493243c69dc627770e4f3edcfd1f78be0（30%USDT到底池买币转到这个地址，即矿池地址） 
入金50%地址：0x438003f621cb1bfe2a1fb7dfe02962b0455e5675===>市值管理钱包 
 
当有人卖出代币 市值钱包自动跟买105%的代币  
买入销毁8%地址：黑洞地址 
运营买入2%地址：0xAF84D6a073bBbc678899671b9BA3669811018982 
90%转到地址：0xec94798493243c69dc627770e4f3edcfd1f78be0(矿池地址)