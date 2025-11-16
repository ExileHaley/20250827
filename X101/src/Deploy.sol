// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {X101} from "./X101.sol";

contract Deploy {
    address public deployedAddress;
    address public constant ADX = 0xaF3A1f455D37CC960B359686a016193F72755510;

    event TokenDeployed(address indexed tokenAddress, bytes32 salt);

    function deployX101(
        address _initialRecipient,
        address _sellFee
    ) external returns (address) {
        bytes32 salt;
        address predicted;

        // 尝试不同 salt，直到生成地址大于 USDT
        for (uint256 i = 0; i < 1000; i++) {
            salt = keccak256(abi.encodePacked(_initialRecipient, _sellFee, i));
            predicted = _predictAddress(_initialRecipient, _sellFee, salt);
            if (predicted > ADX) {
                break;
            }
        }

        bytes memory bytecode = abi.encodePacked(
            type(X101).creationCode,
            abi.encode(_initialRecipient, _sellFee)
        );

        address addr;
        assembly {
            addr := create2(0, add(bytecode, 32), mload(bytecode), salt)
            if iszero(extcodesize(addr)) { revert(0, 0) }
        }

        deployedAddress = addr;
        emit TokenDeployed(addr, salt);
        return addr;
    }

    function predictAddress(
        address _initialRecipient,
        address _sellFee,
        bytes32 salt
    ) external view returns (address) {
        return _predictAddress(_initialRecipient, _sellFee, salt);
    }

    function _predictAddress(
        address _initialRecipient,
        address _sellFee,
        bytes32 salt
    ) internal view returns (address predicted) {
        bytes memory bytecode = abi.encodePacked(
            type(X101).creationCode,
            abi.encode(_initialRecipient, _sellFee)
        );
        bytes32 bytecodeHash = keccak256(bytecode);
        bytes32 data = keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, bytecodeHash));
        predicted = address(uint160(uint256(data)));
    }

    function transferOwnership(address newOwner) external {
        X101(deployedAddress).transferOwnership(newOwner);
    }
}
