// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { EIP712Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import { SignatureChecker } from "./libraries/SignatureChecker.sol";
import { SignatureInfo } from "./libraries/SignatureInfo.sol";

import {TransferHelper} from "./libraries/TransferHelper.sol";
import {ReentrancyGuard} from "./libraries/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IStaking} from "./interfaces/IStaking.sol";

contract Staking is Initializable, OwnableUpgradeable, EIP712Upgradeable, UUPSUpgradeable, ReentrancyGuard, IStaking{
    

    using ECDSA for bytes32;
    bytes32 public constant SIGN_TYPEHASH = keccak256(
        "SignMessage(string mark,address token,address recipient,uint256 amount,uint256 fee,uint256 nonce,uint256 deadline)"
    );

    mapping(address => bool) public isStaking;
    mapping(string => bool) public isExcuted;
    mapping(address => Identity) public identityInfo;
    
    address public cessToken;
    address public cfunToken;
    address public recipient;
    address public admin;
    address public signer;

    uint256 public override nonce;
    uint256 public constant MIN_STAKE = 10000 * 1e18;
    mapping(address => bool) whitelist;

    receive() external payable{}

    modifier onlyAdmin() {
        require(msg.sender == admin, "Error_admin.");
        _;
    }

    function initialize(
        address _cessToken,
        address _cfunToken, 
        address _recipient, 
        address _admin, 
        address _signer,
        address[] calldata _addrs
    ) public initializer {
        __EIP712_init_unchained("Staking", "1");
        __Ownable_init_unchained(_msgSender());
        __UUPSUpgradeable_init_unchained();
        cessToken = _cessToken;
        cfunToken = _cfunToken;
        recipient = _recipient;
        admin = _admin;
        signer = _signer;
        //初始化whitelist
        addWhitelist(_addrs);
    }

    function setTokenAddr(address _cessToken, address _cfunToken, address _recipient, address _signer) external onlyOwner{
        cessToken = _cessToken;
        cfunToken = _cfunToken;
        recipient = _recipient;
        signer = _signer;
    }

    function addWhitelist(address[] calldata addrs) private{
        for(uint i=0; i<addrs.length; i++){
            whitelist[addrs[i]] = true;
        }
    }

     // Authorize contract upgrades only by the owner
    function _authorizeUpgrade(address newImplementation) internal view override onlyOwner(){}

    function addIdentity(address[] calldata addrs, Identity identity) external onlyOwner{
        for(uint i=0; i<addrs.length; i++){
            identityInfo[addrs[i]] = identity;
        }
    }

    function stake(uint256 amount) external {
        require(amount >= MIN_STAKE, "Error_stake_amount.");
        TransferHelper.safeTransferFrom(cessToken, msg.sender, address(this), amount);
        isStaking[msg.sender] = true;
        emit Stake(msg.sender, amount, identityInfo[msg.sender], block.timestamp);
    }

    function emergencyWithdraw() external nonReentrant onlyAdmin {
        uint256 cessAmount = IERC20(cessToken).balanceOf(address(this));
        uint256 cfunAmount = IERC20(cfunToken).balanceOf(address(this));
        if(cessAmount > 0) TransferHelper.safeTransfer(cessToken, msg.sender, cessAmount);
        if(cfunAmount > 0) TransferHelper.safeTransfer(cfunToken, msg.sender, cfunAmount);
    }

    function getSignMsgHash(SignatureInfo.SignMessage memory _msg) public view override returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(
            SIGN_TYPEHASH,
            keccak256(abi.encodePacked(_msg.mark)),
            _msg.token,
            _msg.recipient,
            _msg.amount,
            _msg.fee,
            _msg.nonce,
            _msg.deadline
        )));
    }

    function checkerSignMsgSignature(SignatureInfo.SignMessage memory _msg) public view override returns (bool) {
        bytes32 signMsgHash = getSignMsgHash(_msg);
        address recoveredSigner = ECDSA.recover(signMsgHash, _msg.v, _msg.r, _msg.s);
        return recoveredSigner == signer;
    }

    mapping(address => uint256) public lastWithdrawTime;

    function withdrawWithSignature(SignatureInfo.SignMessage memory _msg) external nonReentrant{

        require(_msg.nonce == nonce, "Nonce error.");
        require(_msg.deadline >= block.timestamp, "Deadline error.");
        require(checkerSignMsgSignature(_msg), "Check signature error.");
        if(!whitelist[_msg.recipient])require(isStaking[_msg.recipient], "Not pledged.");

        require(!isExcuted[_msg.mark], "Error excuted.");
        require(
            block.timestamp >= lastWithdrawTime[_msg.recipient] + 1 days,
            "Withdraw only once per 24h"
        );
        

        if (_msg.token != address(0)) {
            TransferHelper.safeTransfer(_msg.token, _msg.recipient, _msg.amount);
            if (_msg.fee > 0) TransferHelper.safeTransfer(_msg.token, recipient, _msg.fee);
        }

        isExcuted[_msg.mark] = true;
        nonce++;
        lastWithdrawTime[_msg.recipient] = block.timestamp; // 更新提取时间

        emit Withdraw(
            _msg.mark,
            _msg.token,
            _msg.recipient,
            _msg.amount,
            _msg.fee,
            _msg.nonce,
            block.timestamp
        );
    }



}