### install foundry-rs/forge-std
```shell
$ forge install foundry-rs/forge-std  --no-git
```
### install openzeppelin-contracts
```shell
$ forge install openzeppelin/openzeppelin-contracts  --no-git
```

### install openzeppelin-contracts-upgradeable
```shell
$ forge install openzeppelin/openzeppelin-contracts-upgradeable  --no-git
```

### deploy wallet
```shell
$ forge script script/Upgrade.s.sol -vvv --rpc-url=https://bsc.blockrazor.xyz --broadcast --private-key=[privateKey]
```


#### 更新abi
#### recharge:0xFC1F7CADFEDd2a5792Ac728b044572c5Cf007776
#### abi:./out/Staking.sol/Staking.json
#### recharge func list:
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
            uint256 referralAward, //当前用户的推荐奖励
            uint256 performance,  //当前用户截止目前的总业绩，伞下所有，有精度
            uint256 referralNum,  //当前用户截止目前的总人数，伞下所有，没有精度
            address[] memory referrals //返回地址数组，当前地址邀请的所有直推地址
        );
//获取全网参与的总人数，没有精度
function getAddrCollectionLength() external view returns(uint);
//判断当前地址是否拥有邀请资格
function validInvitationCode(address user) external view returns(bool);
//用户提取推荐奖励，对应getUserInfo返回的uint256 referralAward
function claim(uint256 amountUSDT) external;
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

struct Record{
        address from; //奖励来源地址
        uint256 amount; //奖励数量
        uint256 time; //奖励发放时间
}
//获取当前用户获得推荐奖励的信息
function getAwardRecords(address user) external view returns(Record[] memory);


//管理端方法
function setRecipient(address _recipient) external;
function emergencyWithdraw(address token, uint256 amount, address to) external;
//2.设置创世节点，手动设置支付gas，使用管理员地址(3),user是要设置的地址，isGenesisNode true/false代表同意/取消
function setGenesisNode(address user, bool isGenesisNode) external;
//3.获取管理员地址
function admin() external view returns(address);
```