// https://eips.ethereum.org/EIPS/eip-20
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import {LibDiamond} from "../libraries/LibDiamond.sol";
// import {IERC20} from "../interfaces/IERC20.sol";

// abstract contract ERC20Facet is IERC20 {
//     uint256 private constant MAX_UINT256 = 2 ** 256 - 1;

//     constructor() {}

//     // function ds() public returns (LibDiamond.DiamondStorage ) {
//     //     // return LibDiamond.diamondStorage();
//     //     LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
//     // }

//     function transfer(
//         address _to,
//         uint256 _value
//     ) public override returns (bool success) {
//         LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

//         require(
//             ds.balances[msg.sender] >= _value,
//             "token balance is lower than the value requested"
//         );
//         ds.balances[msg.sender] -= _value;
//         ds.balances[_to] += _value;
//         // emit Transfer(msg.sender, _to, _value); //solhint-disable-line indent, no-unused-vars
//         return true;
//     }

//     function transferFrom(
//         address _from,
//         address _to,
//         uint256 _value
//     ) public override returns (bool success) {
//         LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

//         uint256 allowance = ds.allowed[_from][msg.sender];
//         require(
//             ds.balances[_from] >= _value && allowance >= _value,
//             "token balance or allowance is lower than amount requested"
//         );
//         ds.balances[_to] += _value;
//         ds.balances[_from] -= _value;
//         if (allowance < MAX_UINT256) {
//             ds.allowed[_from][msg.sender] -= _value;
//         }
//         // emit Transfer(_from, _to, _value); //solhint-disable-line indent, no-unused-vars
//         return true;
//     }

//     function balanceOf(
//         address _owner
//     ) public view override returns (uint256 balance) {
//         LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

//         return ds.balances[_owner];
//     }

//     function approve(
//         address _spender,
//         uint256 _value
//     ) public override returns (bool success) {
//         LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

//         ds.allowed[msg.sender][_spender] = _value;
//         // emit Approval(msg.sender, _spender, _value); //solhint-disable-line indent, no-unused-vars
//         return true;
//     }

//     // function allowance(
//     //     address _owner,
//     //     address _spender
//     // ) public view override returns (uint256 remaining) {
//     //     return ds.allowed[_owner][_spender];
//     // }
// }
