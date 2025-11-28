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

### deploy PCN
```shell
$ forge script script/Fact.s.sol -vvv --rpc-url=https://bsc.blockrazor.xyz --broadcast --private-key=[privateKey]
```

### build token constructor
```shell
$ cast abi-encode "constructor(address,address,address)" 0x3D1f8Da9523f66F7b766b1d3f9502220Db90c181 0x8Da8FA6a5FfDe11Bb9C3A601609625E8eF4716D8 0x8Da8FA6a5FfDe11Bb9C3A601609625E8eF4716D8 
```

### verify token contract
```shell
$ forge verify-contract --chain-id 56 --compiler-version v0.8.30+commit.a1b79de6 0x777924236Fb8F6e3756cbfd1A99ca84a4aff6984 src/Fact.sol:Fact  --constructor-args 0x0000000000000000000000003d1f8da9523f66f7b766b1d3f9502220db90c1810000000000000000000000008da8fa6a5ffde11bb9c3a601609625e8ef4716d80000000000000000000000008da8fa6a5ffde11bb9c3a601609625e8ef4716d8 --etherscan-api-key Y43WNBZNXWR5V4AWQKGAQ9RCQEXTUHK88V

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
    ) external payable;
//调用该方法100%都会打给一个地址
function singleRechargePercent100(address token, uint256 amount, string calldata remark)
        external
        payable;
```

#### Fact address:0x777924236Fb8F6e3756cbfd1A99ca84a4aff6984
#### Pancake pair address:0xba054689f719B7D496502f6700C2Cea6a3107ff9
#### recharge:0x7670f7730EFFB82ef10FAf29eC4EC4bf9338D8C3




