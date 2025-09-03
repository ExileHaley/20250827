// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import {SignatureInfo} from "../libraries/SignatureInfo.sol";

interface IStaking {
    
    enum Identity {
        INVALID,
        BASIC,   // 900
        ADVANCED, // 2900
        ELITE    // 5900
    }

    event Stake(address sender, uint256 amount, Identity identity, uint256 time);
    event Withdraw(string mark, address token, address recipient, uint256 amount, uint256 fee, uint256 nonce, uint256 time);

    function isExcuted(string memory mark) external view returns(bool);
    function nonce() external view returns(uint256);
    function getSignMsgHash(SignatureInfo.SignMessage memory _msg) external view returns (bytes32);
    function checkerSignMsgSignature(SignatureInfo.SignMessage memory _msg) external view returns (bool);
}
