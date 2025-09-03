// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Cfun is ERC20{
    constructor(address _initial)ERC20("Cfun","CFUN"){
        _mint(_initial, 10000e18);
    }
}