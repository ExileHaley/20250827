#### factory:0xf7D6784b7c04bbD687599FF83227F7e4B12c0243
#### router:0x1F7CdA03D18834C8328cA259AbE57Bf33c46647c
#### ADX:0xaF3A1f455D37CC960B359686a016193F72755510
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------

### X101 token address:0xdf26233780Bc95Dd7A0D71801A0E4226cF05671a(代币地址)
### pancakePair:0xB61707E57d4CfADE074343f22490200F0056BC96(和ADX的池子地址)



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