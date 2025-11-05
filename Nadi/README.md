## install and deploy
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
$ forge script script/Recharge.s.sol -vvv --rpc-url=https://rpc.naaidepin.co --broadcast --private-key=[privateKey]
```

## Nadi公链网络参数

#### 公链名称：NadiDepin
#### 公链代币：NADI
#### 链id：399
#### https://rpc.naaidepin.co
#### https://explorer.naaidepin.co



#### WNADI合约:0xe901e30661dd4fd238c4bfe44b000058561a7b0e
#### USDT合约:0x3ea660cDc7b7CCC9F81c955f1F2412dCeb8518A5

## 购买算力分配
#### 入金分配接收地址： 
#### 50%：0xD2d0D05Ae9B339ACBbcD95E3A7210C394102f516 
#### 40%：0x01cA5237D73D530F67c1413B4884b1A9C49D4aAb 
#### 10%：0xF10E3cD6e824A1C169a7F6465Fd2221050154BA4 
#### 接收地址:0x6cE2aeBDC5Bd15EA1fbA0e234d1147433400d4d4
#### GAS费地址：0x6F1fd46936b26C7685670Ec16eF403ec9B826aF9
#### 提现地址：0xF0E57eCc4a4B0FE0Cb3dd724edcE2e3122bddEE1

---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
### abi:./out/recharge.sol/recharge.json
### recharge contract address:0xDD67527123b31a89027DB8D95c885d4140388013
### recharge func
```solidity
//singleRecharge和multiRecharge两个方法都新增了Mode参数；
//这里传1代表全部打给指定地址、2代表按比例打给三个地址，0无效；
//要更新abi；
enum Mode{Invalid,Full,Proportional}
function singleRecharge(Mode mode, address token, uint256 amount, string calldata remark) external payable;
function multiRecharge(
        Mode    mode,
        address token0,
        uint256 amount0,
        address token1,
        uint256 amount1,
        string calldata remark
) external payable;
```