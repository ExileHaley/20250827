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
$ forge script script/DeploySubscribe.s.sol -vvv --rpc-url=https://bsc.blockrazor.xyz --broadcast --private-key=[privateKey]
```

### usdt合约:0x55d398326f99059fF775485246999027B3197955
### Subscribe合约:0x02496aB388d5C6a042D66aCED3ab3dE85F5b4a85
### abi路径:./out/Subscribe.sol/Subscribe.json
### 方法列表
```solidity
//认购方法，amount是用户要认购的usdt数量，分为900u、2900u、5900u三档，页面可以给用直接选择不要输入框
function subscribe(uint256 amount) external;
//查询用户认购信息，subscribeAmount认购的usdt数量、subscribeTime认购时间、subscribed是否认购，一个用户只能认购一次，根据该值决定是否展示认购按钮
function userInfo(address user) external view returns( uint256 subscribeAmount,uint256 subscribeTime,bool subscribed);
//后面三个不用调
function getBasicUsers() external view returns (address[] memory);
function getAdvancedUsers() external view returns (address[] memory);
function getEliteUsersLength() external view returns (address[] memory);
//获取认购信息，length不同档位的认购总人数，totalAmount总认购的usdt数量
function getSubscribeInfo() external view returns(uint256 length, uint256 totalAmount)
```

### staking合约:
### 方法列表
```javascript
```