// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../contracts/interfaces/IDiamondCut.sol";
import "../contracts/facets/DiamondCutFacet.sol";
import "../contracts/facets/DiamondLoupeFacet.sol";
import "../contracts/facets/OwnershipFacet.sol";
import "../contracts/facets/ERC721Facet.sol";
import "./Helpers.sol";
import "../contracts/Diamond.sol";
import "../contracts/facets/MarketplaceFacet.sol";
import {Listing} from "../contracts/libraries/LibDiamond.sol";

contract MarketplaceTest is Test, IDiamondCut, Helpers {
    Diamond diamond;
    DiamondCutFacet dCutFacet;
    DiamondLoupeFacet dLoupe;
    OwnershipFacet ownerF;
    Marketplace marketplace;
    ERC721Facet nft;

    uint256 listingId;

    address userA;
    address userB;

    uint256 privKeyA;
    uint256 privKeyB;

    Listing listing;

    function setUp() public {
        dCutFacet = new DiamondCutFacet();
        diamond = new Diamond(
            address(this),
            address(dCutFacet),
            "SamNft",
            "SNFT"
        );
        dLoupe = new DiamondLoupeFacet();
        ownerF = new OwnershipFacet();
        nft = new ERC721Facet();
        marketplace = new Marketplace();

        FacetCut[] memory cut = new FacetCut[](4);

        cut[0] = (
            FacetCut({
                facetAddress: address(dLoupe),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("DiamondLoupeFacet")
            })
        );

        cut[1] = (
            FacetCut({
                facetAddress: address(ownerF),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("OwnershipFacet")
            })
        );

        cut[2] = (
            FacetCut({
                facetAddress: address(nft),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("ERC721Facet")
            })
        );

        cut[3] = (
            FacetCut({
                facetAddress: address(marketplace),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("Marketplace")
            })
        );

        IDiamondCut(address(diamond)).diamondCut(cut, address(0x0), "");

        DiamondLoupeFacet(address(diamond)).facetAddresses();

        (userA, privKeyA) = mkaddr("USER A");
        (userB, privKeyB) = mkaddr("USER B");

        // console2.log("userA", userA);
        // console2.log("userB", userB);

        listing = Listing({
            token: address(nft),
            tokenId: 1,
            price: 1 ether,
            sig: bytes(""),
            deadline: 0,
            lister: address(0),
            active: false
        });

        nft.mint(userA, 1);

    }

    function generateSelectors(
        string memory _facetName
    ) internal returns (bytes4[] memory selectors) {
        string[] memory cmd = new string[](3);
        cmd[0] = "node";
        cmd[1] = "scripts/genSelectors.js";
        cmd[2] = _facetName;
        bytes memory res = vm.ffi(cmd);
        selectors = abi.decode(res, (bytes4[]));
    }

    // TEST CREATE LISTING

    function testOnlyOwnerCanCreate() public {
        listing.lister = userB;
        switchSigner(userB);
        vm.expectRevert(Marketplace.NotOwner.selector);
        marketplace.createListing(listing);
    }

    function testNotApproved() public {
        switchSigner(userA);
        vm.expectRevert(Marketplace.NotApproved.selector);
        marketplace.createListing(listing);
    }

    function testMinPriceTooLow() public {
        switchSigner(userA);
        listing.price = 0 ether;
        nft.setApprovalForAll(address(marketplace), true);
        vm.expectRevert(Marketplace.MinPriceTooLow.selector);
        marketplace.createListing(listing);
    }

    function testInvalidDeadline() public {
        switchSigner(userA);
        nft.setApprovalForAll(address(marketplace), true);
        vm.expectRevert(Marketplace.InvalidDeadline.selector);
        marketplace.createListing(listing);
    }

    function testMinDurationNotMet() public {
        switchSigner(userA);
        nft.setApprovalForAll(address(marketplace), true);
        listing.deadline = uint88(block.timestamp + 1 hours);
        vm.expectRevert(Marketplace.MinDurationNotMet.selector);
        marketplace.createListing(listing);
    }

    function testInvalidSignature() public {
        switchSigner(userA);
        nft.setApprovalForAll(address(marketplace), true);
        listing.deadline = uint88(block.timestamp + 1 days);
        listing.sig = constructSig(
            listing.token,
            listing.tokenId,
            listing.price,
            uint88(listing.deadline),
            listing.lister,
            privKeyB
        );
        vm.expectRevert(Marketplace.InvalidSignature.selector);
        marketplace.createListing(listing);
    }

    // TEST EXECUTE LISTING

    function testListingNotExistent() public {
        switchSigner(userA);
        nft.setApprovalForAll(address(marketplace), true);
        listing.deadline = uint88(block.timestamp + 1 days);
        listing.sig = constructSig(
            listing.token,
            listing.tokenId,
            listing.price,
            uint88(listing.deadline),
            listing.lister,
            privKeyA
        );
        vm.expectRevert(Marketplace.ListingNotExistent.selector);
        marketplace.executeListing{value: listing.price}(listingId);
    }

    function testListingExpired() public {
        switchSigner(userA);
        nft.setApprovalForAll(address(marketplace), true);
        listing.deadline = uint88(block.timestamp + 1 days);
        listing.sig = constructSig(
            listing.token,
            listing.tokenId,
            listing.price,
            uint88(listing.deadline),
            listing.lister,
            privKeyA
        );
        marketplace.createListing(listing);
        vm.warp(block.timestamp + 2 days);
        vm.expectRevert(Marketplace.ListingExpired.selector);
        marketplace.executeListing{value: listing.price}(listingId);
    }

    function testListingNotActive() public {
        switchSigner(userA);
        nft.setApprovalForAll(address(marketplace), true);
        listing.deadline = uint88(block.timestamp + 1 days);
        listing.sig = constructSig(
            listing.token,
            listing.tokenId,
            listing.price,
            uint88(listing.deadline),
            listing.lister,
            privKeyA
        );
        marketplace.createListing(listing);
        marketplace.executeListing{value: listing.price}(listingId);
        vm.expectRevert(Marketplace.ListingNotActive.selector);
        marketplace.executeListing{value: listing.price}(listingId);
    }

    function testPriceNotMet() public {
        switchSigner(userA);
        nft.setApprovalForAll(address(marketplace), true);
        listing.deadline = uint88(block.timestamp + 1 days);
        listing.sig = constructSig(
            listing.token,
            listing.tokenId,
            listing.price,
            uint88(listing.deadline),
            listing.lister,
            privKeyA
        );
        marketplace.createListing(listing);
        vm.expectRevert(
            abi.encodeWithSelector(
                Marketplace.PriceNotMet.selector,
                listing.price - 0.3 ether
            )
        );
        marketplace.executeListing{value: 0.3 ether}(listingId);
    }

    function testPriceMismatch() public {
        switchSigner(userA);
        nft.setApprovalForAll(address(marketplace), true);
        listing.deadline = uint88(block.timestamp + 1 days);
        // listing.price = 2 ether;
        listing.sig = constructSig(
            listing.token,
            listing.tokenId,
            listing.price,
            uint88(listing.deadline),
            listing.lister,
            privKeyA
        );
        marketplace.createListing(listing);
        vm.expectRevert(
            abi.encodeWithSelector(
                Marketplace.PriceMismatch.selector,
                listing.price
            )
        );
        marketplace.executeListing{value: 3 ether}(listingId);
    }

    function testExecuteListing() public {
        switchSigner(userA);
        nft.setApprovalForAll(address(marketplace), true);
        listing.deadline = uint88(block.timestamp + 1 days);
        listing.sig = constructSig(
            listing.token,
            listing.tokenId,
            listing.price,
            uint88(listing.deadline),
            listing.lister,
            privKeyA
        );
        listingId = marketplace.createListing(listing);
        switchSigner(userB);
        uint256 userABalanceBefore = userA.balance;
        uint256 userBBalanceBefore = userB.balance;
        marketplace.executeListing{value: listing.price}(listingId);
        uint256 userABalanceAfter = userA.balance;
        uint256 userBBalanceAfter = userB.balance;
        assertEq(listing.active, false);
        assertEq(userABalanceAfter - userABalanceBefore, listing.price);
        assertEq(IERC721(listing.token).ownerOf(listing.tokenId), userB);
        console2.log("userABalanceBefore", userABalanceBefore);
        console2.log("userBBalanceBefore", userBBalanceBefore);
        console2.log("userABalanceAfter", userABalanceAfter);
        console2.log("userBBalanceAfter", userBBalanceAfter);
    }

    // TEST EDIT LISTING

    function testEditListingNotExistent() public {
        switchSigner(userA);
        nft.setApprovalForAll(address(marketplace), true);
        uint256 newPrice = listing.price + 1 ether;
        vm.expectRevert(Marketplace.ListingNotExistent.selector);
        marketplace.editListing(listingId, newPrice);
    }

    function testEditNotOwner() public {
        switchSigner(userA);
        nft.setApprovalForAll(address(marketplace), true);
        listing.deadline = uint88(block.timestamp + 1 days);
        listing.sig = constructSig(
            listing.token,
            listing.tokenId,
            listing.price,
            uint88(listing.deadline),
            listing.lister,
            privKeyA
        );
        marketplace.createListing(listing);
        marketplace.executeListing{value: listing.price}(listingId);
        uint256 newPrice = listing.price + 1 ether;
        switchSigner(userB);
        vm.expectRevert(Marketplace.NotOwner.selector);
        marketplace.editListing(listingId, newPrice);
    }

    function testZEditListing() public {
        switchSigner(userA);
        nft.setApprovalForAll(address(marketplace), true);
        listing.deadline = uint88(block.timestamp + 1 days);
        listing.sig = constructSig(
            listing.token,
            listing.tokenId,
            listing.price,
            uint88(listing.deadline),
            listing.lister,
            privKeyA
        );
        marketplace.createListing(listing);
        marketplace.executeListing{value: listing.price}(listingId);
        uint256 newPrice = listing.price + 1 ether;
        marketplace.editListing(listingId, newPrice);
        Listing memory listing = marketplace.getListing(listingId);
        assertEq(listing.price, newPrice);
        assertEq(listing.active, true);
    }

    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {}
}
