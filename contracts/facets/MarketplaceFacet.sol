// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "node_modules/@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "node_modules/@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "node_modules/@openzeppelin/contracts/utils/Address.sol";

contract Marketplace {

    error NotOwner();
    error NotApproved();
    error AddressZero();
    error NoCode();
    error MinPricedTooLow();
    error DeadlineTooSoon();
    error MinDurationNotMet();
    error InvalidSignature();

    error ListingNotExistent();
    error ListingNotActive();
    error PriceNotMet(uint256 difference);
    error PriceMismatch(); //why?
    error ListingExpired();

    constructor() {
        admin = msg.sender;
    }

    function createListing(Listing calldata l) public {
        //made returns(uint256 lid)
        if (IERC721(l.token).ownerOf(l.tokenId) != msg.sender)
            revert NotOwner();
        if (!IERC721(l.token).isApprovedForAll(msg.sender, address(this)))
            //confirm!
            revert NotApproved();
        if (l.token == address(0)) revert AddressZero();
        if (l.price < 0.01 ether) revert MinPricedTooLow();
        if (l.token.code.length == 0) revert NoCode();
        if (l.deadline < block.timestamp) revert DeadlineTooSoon();
        if (l.deadline - block.timestamp < 1 days) revert MinDurationNotMet();

        //assert signature
        bytes32 hash = keccak256(
            abi.encodePacked(
                l.token,
                l.tokenId,
                l.price,
                msg.sender,
                l.deadline
            )
        );
        if (ECDSA.recover(hash, l.sig) != l.lister) revert InvalidSignature();

        //append to storage
        Listing storage listing = listings[listingId];
        listing.lister = l.lister;
        listing.token = l.token;
        listing.tokenId = l.tokenId;
        listing.price = l.price;
        listing.sig = l.sig;
        listing.deadline = l.deadline;
        listing.active = l.active;
        listingId++;
    }

    function executeListing(uint256 _listingId) public payable {
        if (_listingId >= listingId) revert ListingNotExistent();
        Listing storage listing = listings[_listingId];
        if (listing.deadline < block.timestamp) revert ListingExpired();
        if (!listing.active) revert ListingNotActive();
        if (listing.price > msg.value)
            revert PriceNotMet(listing.price - msg.value);
        if (listing.price != msg.value) revert PriceMismatch();
        //update state
        listing.active = false;
        //transfer
        IERC721(listing.token).transferFrom(
            listing.lister,
            msg.sender,
            listing.tokenId
        );
        //transferETH
        payable(listing.lister).transfer(listing.price);
    }

    function editListing(uint256 _listingId, uint256 newPrice) public {
        if (_listingId >= listingId) revert ListingNotExistent();
        Listing storage listing = listings[_listingId];
        if (listing.lister != msg.sender) revert NotOwner();
        listing.price = newPrice;
        listing.active = true;
    }

    function getListing(
        uint256 _listingId
    ) public view returns (Listing memory) {
        if (_listingId >= listingId) return listings[_listingId];
    }
}
