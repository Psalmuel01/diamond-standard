// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function isApprovedForAll(
        address owner,
        address operator
    ) external view returns (bool);

    function transferFrom(address from, address to, uint256 tokenId) external;
}
