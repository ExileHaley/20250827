// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DJSNfts is ERC721, Ownable {
    uint256 private _currentTokenId;
    string private baseURI;
    address public recharge;

    constructor() ERC721("DJSNFTs", "DNs")Ownable(msg.sender) {}

    modifier onlyRecharge() {
        require(recharge == msg.sender, "NO_PERMIT.");
        _;
    }

    function setRecharge(address _recharge) external onlyOwner{
        require(_recharge!=address(0),"ZERO_ADDRESS.");
        recharge = _recharge;
    }

    /// @notice Mint 一个 NFT 给某个地址
    function mint(address to) external onlyRecharge{
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
