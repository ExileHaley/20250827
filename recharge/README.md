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

### deploy
```shell
$ forge script script/Recharge.s.sol -vvv --rpc-url=https://bsc.blockrazor.xyz --broadcast --private-key=[privateKey]
```

### rechage(SCC):0x69C2504C9B271b985E02e94d7Ac682a069A2cBFF
### recharge(NVH):

### test(不要使用，仅测试):0x125aCcd5f62d94b0A24E0bBef44fd763b22B077F

### abi:./out/recharge.sol/recharge.json

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
