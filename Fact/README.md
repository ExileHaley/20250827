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
$ cast abi-encode "constructor(address,address,address)" 0x3D1f8Da9523f66F7b766b1d3f9502220Db90c181 0xdfC967EfE061B8aA715Cce39f1A6ba47B0AB3D59 0xe98a4027Fd01e7A5F181541b4b4b56ed11B2B4C0 
```

### verify token contract
```shell
$ forge verify-contract --chain-id 56 --compiler-version v0.8.30+commit.a1b79de6 0x087b767350Be8be45b59cBd5ea794C23002Aa38D src/Fact.sol:Fact  --constructor-args 0x0000000000000000000000003d1f8da9523f66f7b766b1d3f9502220db90c181000000000000000000000000dfc967efe061b8aa715cce39f1a6ba47b0ab3d59000000000000000000000000e98a4027fd01e7a5f181541b4b4b56ed11b2b4c0 --etherscan-api-key Y43WNBZNXWR5V4AWQKGAQ9RCQEXTUHK88V

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

#### Fact address:0x087b767350Be8be45b59cBd5ea794C23002Aa38D
#### Pancake pair address:0x1dF1452589333B332cbB83D3f94e647Cc29aB174
#### recharge:0xA03Abb04C22c440964E47be7013EcB64d76D5561

