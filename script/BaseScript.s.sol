// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { CollisionCheck } from "./utils/CollisionCheck.sol";
import { Script, console2 } from "forge-std/Script.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {
    ITransparentUpgradeableProxy,
    TransparentUpgradeableProxy
} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

interface Proxy {
    function upgradeTo(address newImplementation) external;
    function upgradeToAndCall(address newImplementation, bytes memory data) external;
}

contract BaseScript is CollisionCheck {
    bytes internal constant _EMPTY_PARAMS = "";

    function getAdmin() public virtual returns (address) {
        return getContractAddress(type(ProxyAdmin).name, block.chainid);
    }

    /**
     * * @dev Replace the contract file, including the file extension.
     *
     * ! This must be overridden when your contract name and contract file name do not match.
     */
    function contractFile() public view virtual returns (string memory) { }

    /**
     * @dev Deploy a non-proxy contract and return the deployed address.
     */
    function deployRaw(string memory contractName, bytes memory args) public returns (address) {
        address deployment = deployCode(_prefixName(contractName), args);

        _deploymentLogs(address(0), deployment, contractName, block.chainid);

        vm.label(deployment, contractName);
        return deployment;
    }

    /**
     * @dev Deploy a proxy contract and return the address of the deployed payable proxy.
     */
    function deployProxyRaw(
        string memory contractName,
        bytes memory args,
        string memory kind
    )
        public
        returns (address payable)
    {
        address payable proxy;
        address implementation = deployCode(_prefixName(contractName), _EMPTY_PARAMS);

        if (_areStringsEqual(kind, "uups")) {
            proxy = payable(address(new ERC1967Proxy(implementation, args)));
        }
        if (_areStringsEqual(kind, "transparent")) {
            proxy = payable(address(new TransparentUpgradeableProxy(implementation, getAdmin(), args)));
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
    function upgradeTo(address proxy, string memory contractName, string memory kind, bool skip) public {
        address preComputedAddress = _computeAddressByUpgrader();

        _deploymentLogs(proxy, preComputedAddress, contractName, block.chainid);
        _storageLayoutTemp(_getContractLogPath(contractName, block.chainid));

        if (skip) {
            address newImplementation = deployCode(_prefixName(contractName), _EMPTY_PARAMS);
            if (preComputedAddress != newImplementation) {
                _overrideNullStorageLayout(_getContractLogPath(contractName, block.chainid));
                revert("Wrong address.");
            }
            if (_areStringsEqual(kind, "uups")) {
                Proxy(proxy).upgradeTo(newImplementation);
            } else if (_areStringsEqual(kind, "transparent")) {
                ProxyAdmin(getAdmin()).upgrade(ITransparentUpgradeableProxy(proxy), newImplementation);
            } else {
                _overrideNullStorageLayout(_getContractLogPath(contractName, block.chainid));
                revert("Unsupported your kind of proxy.");
            }
        } else {
            _diff();

            bool success = _checkForCollision(contractName, block.chainid);
            // show diff log:
            if (success) {
                console2.log("\n==========================", unicode"\nAuto compatibility check: ✅ Passed");
            } else {
                console2.log("\n==========================", unicode"\nAuto compatibility check: ❌ Failed");
            }

            console2.log(
                "\n==========================",
                "\nIf you sure storage slot not collision. ",
                "\nSet assign true to skip variable"
            );

            _overrideNullStorageLayout(_getContractLogPath(contractName, block.chainid));
        }

        _rmrf(_getTemporaryStoragePath(""));
    }

    /**
     * @dev Utilized in the event of upgrading to new logic, along with associated data.
     */
    function upgradeToAndCall(
        address proxy,
        string memory contractName,
        bytes memory data,
        string memory kind,
        bool skip
    )
        public
    {
        address preComputedAddress = _computeAddressByUpgrader();

        _deploymentLogs(proxy, preComputedAddress, contractName, block.chainid);
        _storageLayoutTemp(_getContractLogPath(contractName, block.chainid));

        if (skip) {
            address newImplementation = deployCode(_prefixName(contractName), _EMPTY_PARAMS);
            if (preComputedAddress != newImplementation) {
                _rmrf(_getTemporaryStoragePath(""));
                _overrideNullStorageLayout(_getContractLogPath(contractName, block.chainid));
                revert("Wrong address.");
            }

            if (_areStringsEqual(kind, "uups")) {
                Proxy(proxy).upgradeToAndCall(newImplementation, data);
            } else if (_areStringsEqual(kind, "transparent")) {
                ProxyAdmin(getAdmin()).upgradeAndCall(ITransparentUpgradeableProxy(proxy), newImplementation, data);
            } else {
                _rmrf(_getTemporaryStoragePath(""));
                _overrideNullStorageLayout(_getContractLogPath(contractName, block.chainid));
                revert("Unsupported your kind of proxy.");
            }
        } else {
            _diff();

            bool success = _checkForCollision(contractName, block.chainid);
            // show diff log:
            if (success) {
                console2.log("\n==========================", unicode"\nAuto compatibility check: ✅ Passed");
            } else {
                console2.log("\n==========================", unicode"\nAuto compatibility check: ❌ Failed");
            }
            console2.log("\n==========================");
            console2.log(
                unicode"\n ❗️",
                "\nIf you sure storage slot not collision. ",
                "\nAssign the value true to the skip param.",
                "\n=========================="
            );

            _overrideNullStorageLayout(_getContractLogPath(contractName, block.chainid));
        }
        _rmrf(_getTemporaryStoragePath(""));
    }

    function _prefixName(string memory name) internal view returns (string memory) {
        if (abi.encodePacked(contractFile()).length != 0) {
            return string.concat(contractFile(), ":", name);
        }
        return string.concat(name, ".sol:", name);
    }

    function _computeAddressByUpgrader() internal view returns (address) {
        address sender = vm.addr(vm.envUint("UPGRADER_PRIVATE_KEY"));
        return computeCreateAddress(sender, uint256(vm.getNonce(sender)));
    }
}
