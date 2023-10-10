// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../contracts/interfaces/IDiamondCut.sol";
import "../contracts/facets/DiamondCutFacet.sol";
import "../contracts/facets/DiamondLoupeFacet.sol";
import "../contracts/facets/OwnershipFacet.sol";
// import "../contracts/facets/ERC20Facet.sol";
import "../contracts/facets/ERC721Facet.sol";
import "../contracts/facets/Marketplace.sol";
import "forge-std/Test.sol";
import "../contracts/Diamond.sol";

contract DiamondDeployer is Test, IDiamondCut {
    //contract types of facets to be deployed
    Diamond diamond;
    DiamondCutFacet dCutFacet;
    DiamondLoupeFacet dLoupe;
    OwnershipFacet ownerF;
    // ERC20Facet erc20;
    ERC721Facet erc721;
    Marketplace marketplace;

    function setUp() public {
        //deploy facets
        dCutFacet = new DiamondCutFacet();
        diamond = new Diamond(
            address(this),
            address(dCutFacet),
            "SamNft",
            "SNFT"
            // "Samuel",
            // "SAM"
        );
        dLoupe = new DiamondLoupeFacet();
        ownerF = new OwnershipFacet();
        // erc20 = new ERC20Facet();
        erc721 = new ERC721Facet();
        marketplace = new Marketplace();

        //upgrade diamond with facets

        //build cut struct
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
                facetAddress: address(erc721),
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

        //upgrade diamond
        IDiamondCut(address(diamond)).diamondCut(cut, address(0x0), "");

        //call a function
        DiamondLoupeFacet(address(diamond)).facetAddresses();
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

    function testName() public {
        assertEq(ERC721Facet(address(diamond)).name(), "SamNft");
    }

    function testTransfer() public {
        vm.prank(address(0x0));
        ERC721Facet(address(diamond)).transferFrom(address(0x0), address(0x1), 1);
        //assert balance
        assertEq(ERC721Facet(address(diamond)).balanceOf(address(0x1)), 1);
    }



    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {}
}
