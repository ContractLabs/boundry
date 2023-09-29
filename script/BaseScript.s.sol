// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { CollisionCheck } from "./utils/CollisionCheck.sol";
import { Script, console2 } from "forge-std/Script.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

interface Proxy {
    function upgradeTo(address newImplementation) external;
    function upgradeToAndCall(address newImplementation, bytes memory data) external;
}

contract BaseScript is CollisionCheck {
    bytes internal constant EMPTY_PARAMS = "";

    /**
     * * @dev Identify the admin of the transparent proxy contract.
     * * for upgradeable feature
     *
     * ! This must be overridden when deploying with a transparent proxy.
     */
    function admin() public view virtual returns (address) { }

    /**
     * * @dev Replace the contract file, including the file extension.
     *
     * ! This must be overridden when your contract name and contract file name do not match.
     */
    function contractFile() public view virtual returns (string memory) { }

    /**
     * @dev Deploy a non-proxy contract and return the deployed address.
     */
    function _deployRaw(string memory contractName, bytes memory args) internal returns (address) {
        address deployment = deployCode(_prefixName(contractName), args);

        _deploymentLogs(address(0), deployment, contractName, block.chainid);

        vm.label(deployment, contractName);
        return deployment;
    }

    /**
     * @dev Deploy a proxy contract and return the address of the deployed payable proxy.
     */
    function _deployProxyRaw(
        string memory contractName,
        bytes memory args,
        string memory kind
    )
        internal
        returns (address payable)
    {
        address payable proxy;
        address implementation = deployCode(_prefixName(contractName), EMPTY_PARAMS);

        if (_areStringsEqual(kind, "uups")) {
            proxy = payable(address(new ERC1967Proxy(implementation, args)));
        }
        if (_areStringsEqual(kind, "transparent")) {
            proxy = payable(address(new TransparentUpgradeableProxy(implementation, admin(), args)));
        }
        if (!_areStringsEqual(kind, "uups") && !_areStringsEqual(kind, "transparent")) {
            revert("Proxy type not currently supported");
        }

        _deploymentLogs(proxy, implementation, contractName, block.chainid);

        vm.label(implementation, string.concat("Logic-", contractName));
        vm.label(proxy, string.concat("Proxy-", contractName));

        return proxy;
    }

    /**
     * @dev Utilized in the event of upgrading to new logic.
     */
    function _upgradeTo(address proxy, string memory contractName) internal {
        address newImplementation = deployCode(_prefixName(contractName), EMPTY_PARAMS);
        _deploymentLogs(proxy, newImplementation, contractName, block.chainid);
        bool success = _checkForCollision(contractName, block.chainid);
        if (success) {
            Proxy(proxy).upgradeTo(newImplementation);
        } else {
            _overrideNullStorageLayout(_getContractLogPath(contractName, block.chainid));
        }
    }

    /**
     * @dev Utilized in the event of upgrading to new logic, along with associated data.
     */
    function _upgradeToAndCall(address proxy, string memory contractName, bytes memory data) internal {
        address newImplementation = deployCode(_prefixName(contractName), EMPTY_PARAMS);
        _deploymentLogs(proxy, newImplementation, contractName, block.chainid);
        bool success = _checkForCollision(contractName, block.chainid);
        if (success) {
            Proxy(proxy).upgradeToAndCall(newImplementation, data);
        } else {
            _overrideNullStorageLayout(_getContractLogPath(contractName, block.chainid));
        }
    }

    function _prefixName(string memory name) internal view returns (string memory) {
        if (abi.encodePacked(contractFile()).length != 0) {
            return string.concat(contractFile(), ":", name);
        }
        return string.concat(name, ".sol:", name);
    }
}
