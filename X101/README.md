#### factory:0xf7D6784b7c04bbD687599FF83227F7e4B12c0243
#### router:0x1F7CdA03D18834C8328cA259AbE57Bf33c46647c
#### ADX:0xaF3A1f455D37CC960B359686a016193F72755510
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------

### X101 token address:0xCC37e50de109483EEdd2dF40557365e3A0D11b62(代币地址)
### pancakePair:0xc9C1B863c46db8080DbA3c618d0a81f142Ac6e50(和ADX的池子地址)
### recharge:0x4Bd252eD923de7B026d3cd0962487bB138294C75



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
$ forge script script/Deploy.s.sol -vvv --rpc-url=https://rpc.naaidepin.co --broadcast --private-key=[privateKey]
```

