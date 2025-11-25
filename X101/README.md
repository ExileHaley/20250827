#### factory:0xf7D6784b7c04bbD687599FF83227F7e4B12c0243
#### router:0x1F7CdA03D18834C8328cA259AbE57Bf33c46647c
#### ADX:0xaF3A1f455D37CC960B359686a016193F72755510
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------

### X101 token address:0xCC37e50de109483EEdd2dF40557365e3A0D11b62(代币地址)
### pancakePair:0xc9C1B863c46db8080DbA3c618d0a81f142Ac6e50(和ADX的池子地址)

------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
### recharge:0x437853274835e6b4B30A13d6726DDbb5AD402E3E


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
$ forge script script/Recharge.s.sol -vvv --rpc-url=https://rpc.naaidepin.co --broadcast --private-key=[privateKey]
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
