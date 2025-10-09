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

### rechage:0x6845F6E58A4DC8606cB839C49DC235063Cf24463

```json
{
  "amount": "100",
  "coin_token": "USDT",
  "contract_address": "0x55d398326f99059ff775485246999027b3197955",
  "from_address": "0x9559f4e715d058ecd172cb6f3775fe8065781262",
  "hash": "0x330db4afa19f332ad2620c665dfb534d09045969c329e5df54f34429c10c7524",
  "main_chain": "bsc",
  "recharge_type": "1",
  "remarks": "PACKAGE2292_202510071426584915",
  "status": "3",
  "to_address": "0x9559f4e715d058ecd172cb6f3775fe8065781262"
}
```