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

### SKP token address:0xdd334B844066941AEe8c5e2b324E62bE7AAe1b3d
### pancake pair address:0x8b1A9A87f9bb82345F52e2bC8EFF17967D542944
### recharge address:0x3EcBceBE0346f7B2e2Ab2B176ec86E766Dcedf2b
### test hash:

