// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Script, console2 } from "forge-std/Script.sol";
import { LibString } from "solady/src/utils/LibString.sol";
import { JSONParserLib } from "solady/src/utils/JSONParserLib.sol";

contract Logger is Script {
    using LibString for *;
    using JSONParserLib for *;

    mapping(uint256 => string) __chainName;

    function setUp() public {
        __chainName[1] = "ethereum";
        __chainName[5] = "goerli";
        __chainName[43_113] = "fuji";
        __chainName[43_114] = "avalanche";
        __chainName[137] = "polygon";
        __chainName[80_001] = "mumbai";
        __chainName[56] = "bsc";
        __chainName[97] = "tbsc";
        __chainName[42_161] = "arbitrum";
        __chainName[421_613] = "tarb";
    }

    function getContractAddress(string memory contractName, uint256 chainId) public view returns (address) {
        string memory json = vm.readFile(_getContractPath(contractName, chainId));
        JSONParserLib.Item memory item = json.parse();
        return vm.parseAddress(item.children()[0].value().replace('"', ""));
    }

    function getProxyKind(string memory contractName, uint256 chainId) public view returns (string memory kind) {
        string memory json = vm.readFile(_getContractPath(contractName, chainId));
        JSONParserLib.Item memory item = json.parse();
        return item.children()[1].value().replace('"', "");
    }

    function _getDeploymentsPath(string memory path) internal pure returns (string memory) {
        return string.concat("deployments/", path);
    }

    function _getChainPath(uint256 chainId, string memory path) internal view returns (string memory) {
        return _getDeploymentsPath(string.concat(__chainName[chainId], "/", path));
    }

    function _getContractPath(string memory contractName, uint256 chainId) internal view returns (string memory) {
        return _getChainPath(chainId, string.concat(contractName, ".json"));
    }
}
