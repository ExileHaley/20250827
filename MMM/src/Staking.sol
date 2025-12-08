// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {TransferHelper} from "./libraries/TransferHelper.sol";
import {ReentrancyGuard} from "./libraries/ReentrancyGuard.sol";


interface IVenus {
    function mint(uint mintAmount) external returns (uint);
    function redeem(uint redeemTokens) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
}

contract Staking is Initializable, OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuard{
    address public constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    address public constant VENUS = 0xfD5840Cd36d94D7229439859C0112a4185BC0255;
    uint256 public constant FIXED_AMOUNT = 1e17;//test
    // uint256 public constant FIXED_AMOUNT = 1000e18;
    uint256 public constant MAX_REFERRAL_DEPTH = 500;
    address public admin;
    address public recipient;
    address public sender;
    address public initialCode;
    
    struct User{
        address recommender;
        uint256 staking;
        uint256 referralAwards;
        uint256 performance;
        uint256 referralNum;
        bool    genesisNode;
    }

    mapping(address => User) public userInfo;
    mapping(address => address[]) public directReferrals;

    uint256 public totalPerformance;
    address[] addrCollection;
    mapping(address => bool) public isAddCollection;
    bool public pause;
    uint256[45] private __gap;

    event Referral(address recommender,address referred);
    event MultiRecharge(address user, address token0, uint256 amount0, address token1, uint256 amount1, string remark);

    receive() external payable {
        revert("NO_DIRECT_SEND");
    }

    // Authorize contract upgrades only by the owner
    function _authorizeUpgrade(address newImplementation) internal view override onlyOwner(){}

    function initialize(
        address _admin,
        address _recipient,
        address _sender,
        address _initialCode
    ) public initializer {
        __Ownable_init(_msgSender());
        // __Ownable_init(); 这是错误的，编译直接报错， __Ownable_init需要一个参数
        admin = _admin;
        recipient = _recipient;
        sender = _sender;
        initialCode = _initialCode;
    }

    modifier Pause() {
        require(!pause, "PAUSE_RECHARGE.");
        _;
    }

    modifier onlyAdmin() {
        require(admin == msg.sender,"ERROR_PERMIT.");
        _;
    }

    function setRecipient(address _recipient) external onlyOwner {
        require(_recipient != address(0), "ZERO_ADDRESS");
        recipient = _recipient;
    }

    function setSender(address _sender) external onlyOwner{
        require(_sender != address(0), "ZERO_ADDRESS.");
        sender = _sender;
    }

    function emergencyWithdraw(address token, uint256 amount, address to) external onlyOwner {
        TransferHelper.safeTransfer(token, to, amount);
    }

    function setPause(bool isPause) external onlyOwner{
        pause = isPause;
    }

    function setGenesisNode(address user, bool isGenesisNode) external onlyAdmin{
        userInfo[user].genesisNode = isGenesisNode;
    }

    function getAddrCollection() external view returns (address[] memory) {
        return addrCollection;
    }

    function referral(address recommender) external nonReentrant Pause{
        require(recommender != address(0),"ZERO_ADDRESS.");
        require(recommender != msg.sender,"INVALID_RECOMMENDER.");
        if(recommender != initialCode) require(userInfo[recommender].recommender != address(0),"RECOMMENDATION_IS_REQUIRED_REFERRAL.");
        require(userInfo[msg.sender].recommender == address(0),"INVITER_ALREADY_EXISTS.");
        userInfo[msg.sender].recommender = recommender;
        directReferrals[recommender].push(msg.sender);

        //collect address
        if (!isAddCollection[msg.sender]) {
            addrCollection.push(msg.sender);
            isAddCollection[msg.sender] = true;
        }

        _processReferralNumber(msg.sender);
        emit Referral(recommender, msg.sender);
    }

    function _processReferralNumber(address user) private{
        address current = userInfo[user].recommender;
        uint256 depth = 0;
        while (current != address(0) && depth < MAX_REFERRAL_DEPTH) {
            if (current == user) {
                break;
            }
            userInfo[current].referralNum += 1;
            current = userInfo[current].recommender;
            depth++;
        }
    }

    function singleRecharge() external nonReentrant Pause{
        require(userInfo[msg.sender].recommender != address(0),"RECOMMENDATION_IS_REQUIRED_RECHARGE.");
        TransferHelper.safeTransferFrom(USDT, msg.sender, address(this), FIXED_AMOUNT);
        // IVenus(VENUS).mint(FIXED_AMOUNT);
        TransferHelper.safeApprove(USDT, VENUS, 0);
        TransferHelper.safeApprove(USDT, VENUS, FIXED_AMOUNT);
        require(IVenus(VENUS).mint(FIXED_AMOUNT) == 0, "VENUS_MINT_FAILED");

        uint256 venusAmount = IERC20(VENUS).balanceOf(address(this));
        TransferHelper.safeTransfer(VENUS, recipient, venusAmount);
        
        userInfo[msg.sender].staking += FIXED_AMOUNT;
        totalPerformance += FIXED_AMOUNT;
        
        if(userInfo[msg.sender].recommender != address(0)) _processReferralPerformanceAndAward(msg.sender, FIXED_AMOUNT);
        emit MultiRecharge(msg.sender, USDT, FIXED_AMOUNT, address(0), 0, "");
    }

    function _processReferralPerformanceAndAward(address user, uint256 amountUSDT) private{
        
        address current = userInfo[user].recommender;
        bool    awarded;

        while (current != address(0)) {
            if (current == user) {
                break;
            }
            userInfo[current].performance += amountUSDT;
            if(userInfo[current].genesisNode && !awarded) {
                userInfo[current].referralAwards += amountUSDT * 15 / 100;
                awarded = true;
            }
            current = userInfo[current].recommender;
        }
    }

    function getUserInfo(address user) 
        external 
        view 
        returns (
            address recommender, 
            uint256 staking, 
            uint256 referralAward,
            uint256 performance, 
            uint256 referralNum, 
            address[] memory referrals
        ) 
    {
        User memory u = userInfo[user];
        address[] memory refs = directReferrals[user];

        return (
            u.recommender,
            u.staking,
            u.referralAwards,
            u.performance,
            u.referralNum,
            refs
        );
    }

    function getDirectReferrals(address user) external view returns(address[] memory){
        return directReferrals[user];
    }


    function getAddrCollectionLength() external view returns(uint){
        return addrCollection.length;
    }

    function validInvitationCode(address user) external view returns(bool){
        if(user == initialCode) return true;
        else return userInfo[user].recommender != address(0);
    }

    function claim(uint256 amountUSDT) external{
        require(amountUSDT <= userInfo[msg.sender].referralAwards,"ERROR_AMOUNT_USDT.");
        TransferHelper.safeTransferFrom(USDT, sender, msg.sender, amountUSDT);
        userInfo[msg.sender].referralAwards -= amountUSDT;
    }

    function getSenderApprove() external view returns(uint256) {
        return IERC20(USDT).allowance(sender, address(this));
    }

    struct DirectReferralsInfo{
        address referral;
        uint256 performance;
    }

    function getDirectReferralsInfo(address user) 
        external 
        view 
        returns (DirectReferralsInfo[] memory) 
    {
        address[] memory referrals = directReferrals[user];
        uint256 len = referrals.length;

        DirectReferralsInfo[] memory infoList = new DirectReferralsInfo[](len);

        for (uint256 i = 0; i < len; i++) {
            address ref = referrals[i];
            infoList[i] = DirectReferralsInfo({
                referral: ref,
                performance: userInfo[ref].performance
            });
        }

        return infoList;
    }


}