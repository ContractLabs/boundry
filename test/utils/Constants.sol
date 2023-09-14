// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.19;

/*
* @dev Import needing contract in folking test
*/
// import { ERC6551Account } from "contracts/internal/base/ERC6551Account.sol";
// import { ERC6551Registry } from "contracts/internal/base/ERC6551Registry.sol";

// helpful constant
bytes constant EMPTY_PARAMS = "";
uint256 constant ZERO_VALUE = 0;
uint256 constant DEFAULT_BALANCE = 1_000 ether;
address constant NULL_ADDRESS = address(0);

// testnet
string constant MUMBAI_RPC = "";
string constant GOERLI_RPC = "";
string constant FUJI_RPC = "";
string constant TBSC_RPC = "";

// mainnet
string constant POLYGON_RPC = "";
string constant ETH_RPC = "";
string constant AVAX_RPC = "";
string constant BSC_RPC = "";

/*
* @dev Declare for folking purposes
*/
// ERC6551Account constant MUMBAI_ACCOUNT_CONTRACT = ERC6551Account(payable(0x2D25602551487C3f3354dD80D76D54383A243358));
// ERC6551Registry constant MUMBAI_REGISTRY_CONTRACT = ERC6551Registry(
//     payable(0x02101dfB77FDE026414827Fdc604ddAF224F0921)
// );
