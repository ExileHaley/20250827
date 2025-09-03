// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {TransferHelper} from "./TransferHelper.sol";
import {ReentrancyGuard} from "./ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Staking is Initializable, OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuard{
    event Stake(address sender, uint256 amount, Identity identity, uint256 time);
    event Claim(string mark, address holder, uint256 amount, uint256 time);
    event Withdraw(string mark, address holder, uint256 amount, uint256 time);

    enum Identity {
        INVALID,
        BASIC,   // 900
        ADVANCED, // 2900
        ELITE    // 5900
    }

    mapping(address => bool) public isStaking;
    mapping(string => bool) public isExcuted;
    mapping(address => Identity) public identityInfo;
    
    address public cessToken;
    address public cfunToken;
    address public recipient;
    address public admin;
    address public signer;

    uint256 public constant MIN_STAKE = 10000 * 1e18;

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
        address _signer
    ) public initializer {
        __Ownable_init_unchained(_msgSender());
        __UUPSUpgradeable_init_unchained();
        cessToken = _cessToken;
        cfunToken = _cfunToken;
        recipient = _recipient;
        admin = _admin;
        signer = _signer;
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

    function claim() external {}

    function withdraw() external {}

}