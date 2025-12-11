// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "./libraries/ReentrancyGuard.sol";

contract NodeDividends is Initializable, OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuard{


    address public staking;

    receive() external payable {
        revert("NO_DIRECT_SEND");
    }

    modifier onlyStaking() {
        require(msg.sender == staking, "Not permit.");
        _;
    }

    // Authorize contract upgrades only by the owner
    function _authorizeUpgrade(address newImplementation) internal view override onlyOwner(){}

    function initialize() public initializer {
        __Ownable_init(_msgSender());
    }

    function updateFarm(uint256 amount) external onlyStaking(){}
    
    function setStaking(address _staking) external onlyOwner{
        staking = _staking;
    }
}