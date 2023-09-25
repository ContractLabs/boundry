// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { UtilsScript } from "./utils/Utils.sol";
import { Script, console2 } from "forge-std/Script.sol";
import { ERC1967Proxy } from
    "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { TransparentUpgradeableProxy } from
    "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

interface Proxy {
    function upgradeTo(address newImplementation) external;
    function upgradeToAndCall(
        address newImplementation,
        bytes memory data
    )
        external;
}

contract BaseScript is Script, UtilsScript {
    bytes internal constant EMPTY_PARAMS = "";

    /**
     * @dev Override when deploy contract with transparent proxy to passing
     * admin
     * for upgradeable feature.
     */
    function admin() public view virtual returns (address) { }

    /**
     * @dev Override when your contract name and contract file name is mismatch.
     */
    function contractFile() public view virtual returns (string memory) { }

    /**
     * @dev Deploy non-proxy contract
     */
    function _deployRaw(
        string memory contractName,
        bytes memory args
    )
        internal
        returns (address)
    {
        address deployment = deployCode(_prefixName(contractName), args);
        vm.label(deployment, contractName);
        return deployment;
    }

    /**
     * @dev Deploy proxy contract
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
        address implementation =
            deployCode(_prefixName(contractName), EMPTY_PARAMS);

        if (_strEquals(kind, "uups")) {
            proxy = payable(address(new ERC1967Proxy(implementation, args)));
        }
        if (_strEquals(kind, "transparent")) {
            proxy = payable(
                address(
                    new TransparentUpgradeableProxy(implementation, admin(), args)
                )
            );
        }
        if (!_strEquals(kind, "uups") && !_strEquals(kind, "transparent")) {
            revert("Proxy type not currently supported");
        }

        _storageLayoutLog(contractName, implementation, block.chainid);

        vm.label(implementation, string.concat("Logic-", contractName));
        vm.label(proxy, string.concat("Proxy-", contractName));

        return proxy;
    }

    /**
     * @dev Using in case upgrade new logic
     */
    function _upgradeTo(
        address proxy,
        address oldImplementation,
        string memory contractName
    )
        internal
    {
        address newImplementation =
            deployCode(_prefixName(contractName), EMPTY_PARAMS);
        _storageLayoutLog(contractName, newImplementation, block.chainid);
        _collisionCheck(
            contractName, oldImplementation, newImplementation, block.chainid
        );
        Proxy(proxy).upgradeTo(newImplementation);
    }

    /**
     * @dev Using in case upgrade new logic with data
     */
    function _upgradeToAndCall(
        address proxy,
        address oldImplementation,
        string memory contractName,
        bytes memory data
    )
        internal
    {
        address newImplementation =
            deployCode(_prefixName(contractName), EMPTY_PARAMS);
        _storageLayoutLog(contractName, newImplementation, block.chainid);
        _collisionCheck(
            contractName, oldImplementation, newImplementation, block.chainid
        );
        Proxy(proxy).upgradeToAndCall(newImplementation, data);
    }

    function _prefixName(string memory name) internal returns (string memory) {
        if (abi.encodePacked(contractFile()).length != 0) {
            return string.concat(contractFile(), ":", name);
        }
        return string.concat(name, ".sol:", name);
    }

    function _strEquals(
        string memory str1,
        string memory str2
    )
        internal
        pure
        returns (bool)
    {
        return keccak256(abi.encodePacked(str1))
            == keccak256(abi.encodePacked(str2));
    }
}
