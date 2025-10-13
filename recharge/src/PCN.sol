// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract PCN is ERC20, Ownable{

    constructor(address _recipient)ERC20("PCN","PCN") Ownable(msg.sender){
        _mint(_recipient, 1000000000e18);
    }
}