// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../contracts/interfaces/IDiamondCut.sol";
import "../contracts/facets/DiamondCutFacet.sol";
import "../contracts/facets/DiamondLoupeFacet.sol";
import "../contracts/facets/OwnershipFacet.sol";
// import "../contracts/facets/ERC20Facet.sol";
import "../contracts/facets/ERC721Facet.sol";
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

    function setUp() public {
        //deploy facets
        dCutFacet = new DiamondCutFacet();
        diamond = new Diamond(
            address(this),
            address(dCutFacet),
            "SamNft",
            "SNFT"
        );
        dLoupe = new DiamondLoupeFacet();
        ownerF = new OwnershipFacet();
        // erc20 = new ERC20Facet();
        erc721 = new ERC721Facet();

        //upgrade diamond with facets

        //build cut struct
        FacetCut[] memory cut = new FacetCut[](3);

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

    // function testSymbol() public {
    //     assertEq(ERC721Facet(address(diamond)).symbol(), "SNFT");
    // }

    // function testBalanceOf() public {
    //     ERC721Facet(address(diamond)).mint(address(0x1), 1);
    //     assertEq(ERC721Facet(address(diamond)).balanceOf(address(0x1)), 1);
    // }

    // function testBalanceOfWrongAddress() public {
    //     ERC721Facet(address(diamond)).mint(address(0x1), 1);
    //     assertEq(ERC721Facet(address(diamond)).balanceOf(address(0x2)), 0);
    // }

    // function testOwnerOf() public {
    //     ERC721Facet(address(diamond)).mint(address(0x1), 1);
    //     assertEq(ERC721Facet(address(diamond)).ownerOf(1), address(0x1));
    // }

    // function testTransfer() public {
    //     ERC721Facet(address(diamond)).mint(address(0x1), 1);
    //     vm.prank(address(0x1));
    //     ERC721Facet(address(diamond)).transferFrom(
    //         address(0x1),
    //         address(0x2),
    //         1
    //     );
    //     //assert balance
    //     assertEq(ERC721Facet(address(diamond)).balanceOf(address(0x2)), 1);
    // }

    // function testMint() public {
    //     ERC721Facet(address(diamond)).mint(address(0x1), 1);
    //     assertEq(ERC721Facet(address(diamond)).ownerOf(1), address(0x1));
    // }

    // function testFailMint() public {
    //     ERC721Facet(address(diamond)).mint(address(0x1), 1);
    //     assertEq(ERC721Facet(address(diamond)).ownerOf(1), address(0x2));
    // }

    // function testBurn() public {
    //     ERC721Facet(address(diamond)).mint(address(0x1), 1);
    //     assertEq(ERC721Facet(address(diamond)).balanceOf(address(0x1)), 1);
    //     ERC721Facet(address(diamond)).burn(1);
    //     assertEq(ERC721Facet(address(diamond)).balanceOf(address(0x1)), 0);
    // }

    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {}
}
