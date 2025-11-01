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


### deploy subscribe
```shell
$ forge script script/DeploySubscribe.s.sol -vvv --rpc-url=https://bsc.blockrazor.xyz --broadcast --private-key=[privateKey]
```

### deploy staking
```shell
$ forge script script/DeployStaking.s.sol -vvv --rpc-url=https://bsc.blockrazor.xyz --broadcast --private-key=[privateKey]
```

### deploy exchange
```shell
$ forge script script/DeployExchange.s.sol -vvv --rpc-url=https://bsc.blockrazor.xyz --broadcast --private-key=[privateKey]
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


### cfun代币合约: 0x329d91bBCC0214d6Ef4017B9EC2d99Eff409969f
### staking合约:0x5C9D3252ba1EBd5c5d047C0C9cf9e022ccE16950
### abi路径:./out/Staking.sol/Staking.json
### 方法列表
```javascript
//用户质押cess，amount是cess的数量，要求10000个起步
function stake(uint256 amount) external;
struct SignMessage{
        string  mark; //标识，不要重复
        address token; //代币合约地址
        address recipient; //代币接收者
        uint256 amount; //要提现代币的数量
        uint256 fee; //提现手续费
        uint256 nonce; //nonce值
        uint256 deadline; //签名有效截止时间戳
        uint8 v; // v: parameter (27 or 28)
        bytes32 r; // r: parameter
        bytes32 s;
    } 
//提现，参数传上面这个结构体
function withdrawWithSignature(SignatureInfo.SignMessage memory _msg) external
```

### 兑换合约
### 方法列表
```javascript
//输入cess数量可以得到能兑换的cfun数量，预览兑换结果，cessAmount是cess的数量，cfunAmount返回的是cfun的数量
function getExchangeResult(uint256 cessAmount) public view returns (uint256 cfunAmount);
//兑换，输入的是cess的数量，cessAmount是cess的数量
function exchange(uint256 cessAmount) external;
//查询用户钱包，token要查询的代币合约地址，user要查询的钱包地址
function getBalance(address token, address user) external view returns(uint256 amount);
```


### 部署正式版本
### 认购合约(Subscribe):0xaef41D3c4665F6e2E91c968D94d0308d70ea5550
### 质押合约(Staking):0x622e37DAE879e6c5b8e6388Ec0b09D1BFAdB9929
### 兑换合约(Exchange):0x1C86a75B91a897294ca213b075fb614F46E09aaD



### apifox
submitones 在 Apifox 邀请你加入团队 个人团队 https://app.apifox.com/invite?token=O5UP9xgCe-YuXDZsBVsTT

### 认购合约(Subscribe):0x332cD7637A0d2F3E280271886E004F98A025D4da



### deploy subscribe
```shell
$ forge script script/DeploySubscribeV2.s.sol -vvv --rpc-url=https://bsc.blockrazor.xyz --broadcast --private-key=[privateKey]
```


## 基于cess的代码修改其他项目，cess并未上线，上述地址请忽略
### abi:./out/SubscribeV2.sol/SubscribeV2.json
### 认购合约最新地址:0xc20eb9e2089A074130C89F6Bd9b18f74f40efd9d
```solidity
enum Level {
        INVALID,   // 0 无效
        MICRO,     // 1 微型
        BASIC,     // 2 初级
        MIDDLE,    // 3 中级
        ADVANCED   // 4 高级
}
//level输入等级，这里是1/2/3/4，返回购买该等级所需要的usdt数量
function levelPrice(Level level) external view returns(uint256 amount);
//查询用户信息，amount是已购买等级支付的usdt数量，time是购买等级的时间，level是当前等级，subscribed是否已经购买等级
function getUserInfo(address user)external view returns (uint256 amount,uint256 time,Level level,bool subscribed);
//购买会员等级,level是1/2/3/4
//1.根据levelPrice查询所需usdt，如果用户钱包余额不足，则提示；
//2.根据getUserInfo中返回的subscribed判断是否可以认购，true的表示已经认购过了，不允许重复认购
function subscribe(Level level) external;
```
