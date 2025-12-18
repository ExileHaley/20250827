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
$ forge script script/Deploy.s.sol -vvv --rpc-url=https://bsc.blockrazor.xyz --broadcast --private-key=[privateKey] --slow
```

### verify token contract
```shell
$ forge verify-contract --chain-id 56 --compiler-version v0.8.30+commit.a1b79de6 0x7D5014e549E83F2Abb1F346caCd9773245D51923 src/Skp.sol:Skp  --constructor-args 0x000000000000000000000000d4360fae9a810be17b5fc1edf12849675996f71200000000000000000000000073832d01364c48e4b6c49b9ecbf07ab92852b67c000000000000000000000000940fa6e4dcbba8fb25470663849b815a732a021c --etherscan-api-key Y43WNBZNXWR5V4AWQKGAQ9RCQEXTUHK88V


### build token constructor
```shell
$ cast abi-encode "constructor(address,address,address)" 0xD4360fAE9a810Be17b5fC1edF12849675996f712 0x73832D01364c48e4b6C49B9ECBF07aB92852B67c 0x940FA6e4dCBBA8Fb25470663849B815a732a021C 



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

### SKP token address:0x7D5014e549E83F2Abb1F346caCd9773245D51923
### pancake pair address:0x3677B1BD719b1CBEa31E7B321f19ED12745a33d2
### recharge address:0x5c16d6dC352FfCD8b723b15001f99858857cbB43


