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
$ forge script script/PCN.s.sol -vvv --rpc-url=https://bsc.blockrazor.xyz --broadcast --private-key=[privateKey]
```

### build token constructor
```shell
$ cast abi-encode "constructor(address)" 0x4605bE06cE69c944e6bc8fAD80eEeD0467867A9c 
```

### verify token contract
```shell
$ forge verify-contract --chain-id 56 --compiler-version v0.8.30+commit.a1b79de6 0x36F2d5ca7464a9eac1F4bcF2e4E73bebd319EAa1 src/PCN.sol:PCN  --constructor-args 0x0000000000000000000000004605be06ce69c944e6bc8fad80eeed0467867a9c --etherscan-api-key Y43WNBZNXWR5V4AWQKGAQ9RCQEXTUHK88V

```

#### rechage(SCC):0x69C2504C9B271b985E02e94d7Ac682a069A2cBFF
#### recharge(NVH):0xCb25a402679b7e09774218747c1834E756b018AB
#### pcn token:0xa3111361fD8a0E373d2472c84f61996B9eC8Aeb6

#### recharge(NVH version2.0):0x437853274835e6b4B30A13d6726DDbb5AD402E3E

#### test(不要使用，仅测试):0x125aCcd5f62d94b0A24E0bBef44fd763b22B077F

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

#### recharge(NVH version3.0):0xa6844b5bd820ef0d48b61900393158C35a9aef57
#### pcn(version3.0):0x36F2d5ca7464a9eac1F4bcF2e4E73bebd319EAa1

