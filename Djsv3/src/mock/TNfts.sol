// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TNfts is ERC721, Ownable {
    uint256 private _currentTokenId;
    string private baseURI;

    constructor() ERC721("TNF", "TNF")Ownable(msg.sender) {}

    

    /// @notice Mint 一个 NFT 给某个地址
    function mint(address to) external onlyOwner{
        _currentTokenId++;
        _mint(to, _currentTokenId);
    }

    /// @notice 设置 BaseURI（可变 metadata 地址）
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    /// @dev ERC721 元数据基本 URL
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}