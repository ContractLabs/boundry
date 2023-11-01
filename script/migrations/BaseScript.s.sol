// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { console2, Logger } from "./Logger.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

import {
    ITransparentUpgradeableProxy,
    TransparentUpgradeableProxy
} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

interface Proxy {
    function upgradeToAndCall(address newImplementation, bytes memory data) external;
}

contract BaseScript is Logger {
    bytes internal constant _EMPTY_PARAMS = "";

    function getAdmin() public pure virtual returns (address) { }

    /**
     * * @dev Replace the contract file, including the file extension.
     *
     * ! This must be overridden when your contract name and contract file name
     * ! do not match.
     */
    function contractFile() public pure virtual returns (string memory) { }

    /**
     * @dev Deploy a non-proxy contract and return the deployed address.
     */
    function deployRaw(string memory contractName, bytes memory args) public returns (address deployment) {
        deployment = deployCode(_prefixName(contractName), args);
    }

    /**
     * @dev Deploy a proxy contract and return the address of the deployed
     * payable proxy.
     */
    function deployProxyRaw(
        string memory contractName,
        bytes memory args,
        string memory kind
    )
        public
        returns (address payable proxy, address implementation, string memory proxyType)
    {
        implementation = deployCode(_prefixName(contractName), _EMPTY_PARAMS);
        proxyType = kind;
        if (_areStringsEqual(kind, "uups")) {
            proxy = payable(address(new ERC1967Proxy(implementation, args)));
        }
        if (_areStringsEqual(kind, "transparent")) {
            proxy = payable(address(new TransparentUpgradeableProxy(implementation, getAdmin(), args)));
        }
        if (!_areStringsEqual(kind, "uups") && !_areStringsEqual(kind, "transparent")) {
            revert("Proxy type not currently supported");
        }
    }

    /**
     * @dev Utilized in the event of upgrading to new logic.
     */
    function upgradeTo(string memory contractName) public returns (address, address) {
        address proxy = getContractAddress(contractName, block.chainid);
        string memory kind = getProxyKind(contractName, block.chainid);
        address newImplementation = deployCode(_prefixName(contractName), _EMPTY_PARAMS);

        if (_areStringsEqual(kind, "uups")) {
            Proxy(proxy).upgradeToAndCall(newImplementation, _EMPTY_PARAMS);
        } else if (_areStringsEqual(kind, "transparent")) {
            ProxyAdmin(getAdmin()).upgradeAndCall(ITransparentUpgradeableProxy(proxy), newImplementation, _EMPTY_PARAMS);
        } else {
            revert("Unsupported your kind of proxy.");
        }

        return (proxy, newImplementation);
    }

    /**
     * @dev Utilized in the event of upgrading to new logic, along with
     * associated data.
     */
    function upgradeToAndCall(string memory contractName, bytes memory data) public returns (address, address) {
        address proxy = getContractAddress(contractName, block.chainid);
        string memory kind = getProxyKind(contractName, block.chainid);

        address newImplementation = deployCode(_prefixName(contractName), _EMPTY_PARAMS);

        if (_areStringsEqual(kind, "uups")) {
            Proxy(proxy).upgradeToAndCall(newImplementation, data);
        } else if (_areStringsEqual(kind, "transparent")) {
            ProxyAdmin(getAdmin()).upgradeAndCall(ITransparentUpgradeableProxy(proxy), newImplementation, data);
        } else {
            revert("Unsupported your kind of proxy.");
        }

        return (proxy, newImplementation);
    }

    function _prefixName(string memory name) internal pure returns (string memory) {
        if (abi.encodePacked(contractFile()).length != 0) {
            return string.concat(contractFile(), ":", name);
        }
        return string.concat(name, ".sol:", name);
    }

    function _areStringsEqual(string memory firstStr, string memory secondStr) internal pure returns (bool) {
        return keccak256(abi.encodePacked(firstStr)) == keccak256(abi.encodePacked(secondStr));
    }
}
