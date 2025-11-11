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
$ forge script script/Recharge.s.sol -vvv --rpc-url=https://bsc.blockrazor.xyz --broadcast --private-key=[privateKey]
```

### deploy PCN
```shell
$ forge script script/Fact.s.sol -vvv --rpc-url=https://bsc.blockrazor.xyz --broadcast --private-key=[privateKey]
```

### build token constructor
```shell
$ cast abi-encode "constructor(address)" 0x4605bE06cE69c944e6bc8fAD80eEeD0467867A9c 
```

### verify token contract
```shell
$ forge verify-contract --chain-id 56 --compiler-version v0.8.30+commit.a1b79de6 0x36F2d5ca7464a9eac1F4bcF2e4E73bebd319EAa1 src/PCN.sol:PCN  --constructor-args 0x0000000000000000000000004605be06ce69c944e6bc8fad80eeed0467867a9c --etherscan-api-key Y43WNBZNXWR5V4AWQKGAQ9RCQEXTUHK88V

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

### test address
#### Fact address: 0x472B135F6E6Db73cF5c5fA2d7e590c8283d1Be78
#### Pancake pair address: 0x6acd99fb361B4506bcd9a8dAf62B11d8cb5863e8