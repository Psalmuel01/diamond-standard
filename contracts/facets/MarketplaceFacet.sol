// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ERC721Facet.sol";
// import "../interfaces/IERC721.sol";
// import "node_modules/@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "node_modules/@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {LibDiamond, Listing} from "../libraries/LibDiamond.sol";
import {SignUtils} from "./libraries/SignUtils.sol";

contract Marketplace {
    error NotOwner();
    error NotApproved();
    error MinPriceTooLow();
    error InvalidDeadline();
    error MinDurationNotMet();
    error InvalidSignature();

    error ListingNotExistent();
    error ListingNotActive();
    error PriceNotMet(uint256 difference);
    error PriceMismatch(uint256 originalPrice); //why?
    error ListingExpired();

    event ListingCreated(uint256 indexed listingId, Listing);
    event ListingExecuted(uint256 indexed listingId, Listing);
    event ListingEdited(uint256 indexed listingId, Listing);

    constructor() {}

    function createListing(Listing calldata l) public returns (uint256 lId) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        if (IERC721(l.token).ownerOf(l.tokenId) != msg.sender)
            revert NotOwner();
        if (!IERC721(l.token).isApprovedForAll(msg.sender, address(this)))
            revert NotApproved();
        if (l.price < 0.01 ether) revert MinPriceTooLow();
        if (l.deadline < block.timestamp) revert InvalidDeadline();
        if (l.deadline - block.timestamp < 1 days) revert MinDurationNotMet();

        if (
            !SignUtils.isValid(
                SignUtils.constructMessageHash(
                    l.token,
                    l.tokenId,
                    l.price,
                    uint88(l.deadline),
                    l.lister
                ),
                l.sig,
                msg.sender
            )
        ) revert InvalidSignature();

        //append to storage
        Listing storage listing = ds.listings[ds.listingId];
        listing.lister = msg.sender;
        listing.token = l.token;
        listing.tokenId = l.tokenId;
        listing.price = l.price;
        listing.sig = l.sig;
        listing.deadline = uint88(l.deadline);
        listing.active = true;

        //emit event
        emit ListingCreated(ds.listingId, listing);
        lId = ds.listingId;
        ds.listingId++;
        return lId;
    }

    function executeListing(uint256 _listingId) public payable {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        if (_listingId >= ds.listingId) revert ListingNotExistent();
        Listing storage listing = ds.listings[_listingId];
        if (listing.deadline < block.timestamp) revert ListingExpired();
        if (!listing.active) revert ListingNotActive();
        if (listing.price > msg.value)
            revert PriceNotMet(listing.price - msg.value);
        if (listing.price != msg.value) revert PriceMismatch(listing.price);

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

        //emit event
        emit ListingExecuted(_listingId, listing);
    }

    function editListing(uint256 _listingId, uint256 newPrice) public {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        if (_listingId >= ds.listingId) revert ListingNotExistent();
        Listing storage listing = ds.listings[_listingId];
        if (listing.lister != msg.sender) revert NotOwner();
        listing.price = newPrice;
        listing.active = true;

        //emit event
        emit ListingEdited(_listingId, listing);
    }

    function getListing(
        uint256 _listingId
    ) public view returns (Listing memory) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.listings[_listingId];
    }
}
