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

### 查看未执行执行nonce
```shell
$ cast nonce [wallet-address] --rpc-url https://bsc.blockrazor.xyz
```

### nft:0x20D872c41B1373FC9772cbda51609359caFB3748
### recharge:0x0e7f2f2155199E2606Ce24C9b2C5C7C3D5960116
### abi:./out/recharge.sol/recharge.json
### recharge func list:
```solidity
//入金是一个固定值500usdt,这个函数会返回500u的固定值,有精度18
function FIXED_AMOUNT() external view returns(uint256);
//获取全网共计入金数量(usdt)，有精度18
function totalPerformance() external view returns(uint256);
//获取全网参与地址，包括充值和未充值的，返回一个地址数组
function getAddrCollection() external view returns (address[] memory);
//获取首码，从该地址向下进行邀请
function initialCode() external view returns(address);
//绑定推荐关系，recommender上级地址
//1.如果不是首码，要求recommender地址的邀请人不能为空，否则报错
//2.recommender不能等于自己的地址，否则报错
//3.recommender如果是0地址报错
//4.当前地址不能拥有邀请人，如果已经被邀请，报错
function referral(address recommender) external;
//充值，因为是固定500u的数量，所以这里不需要传入参数，需要精度
//1.当前充值用户如果没有推荐关系会报错
function singleRecharge() external;
//获取用户信息
function getUserInfo(address user) 
        external 
        view 
        returns (
            address recommender,  //当前用户的推荐人地址
            uint256 staking,      //当前用户截至目前的充值数量，有精度
            uint256 performance,  //当前用户截止目前的总业绩，伞下所有，有精度
            uint256 referralNum,  //当前用户截止目前的总人数，伞下所有，没有精度
            address[] memory referrals //返回地址数组，当前地址邀请的所有直推地址
        );
//获取全网参与的总人数，没有精度
function getAddrCollectionLength() external view returns(uint);
//判断当前地址是否拥有邀请资格
function validInvitationCode(address user) external view returns(bool);
//获取直推信息
struct DirectReferralsInfo{
        address referral; //下级地址
        uint256 performance; //业绩
}
//获取user的直推地址和对应的业绩信息
function getDirectReferralsInfo(address user) 
        external 
        view 
        returns (DirectReferralsInfo[] memory);

```
