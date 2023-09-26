// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Script, console2 } from "forge-std/Script.sol";

contract UtilsScript is Script {
    mapping(string => bool) __madeDir;
    mapping(uint256 => mapping(address => bool)) __storageLayoutGenerated;

    function _storageLayoutLog(string memory contractName, address implement, uint256 chainId) internal {
        if (__storageLayoutGenerated[chainId][implement]) return;

        _mkdir(_basePath(string.concat("storage/", vm.toString(chainId))));

        string[] memory script = new string[](5);
        script[0] = "forge";
        script[1] = "inspect";
        script[2] = contractName;
        script[3] = "storage-layout";
        script[4] = "--pretty";
        bytes memory out = vm.ffi(script);

        vm.writeFile(_getStorageLayoutPath(implement, chainId), string(out));

        __storageLayoutGenerated[chainId][implement] = true;
    }

    function _collisionCheck(
        string memory contractName,
        address oldImplementation,
        address newImplementation,
        uint256 chainId
    )
        internal
    {
        _headOf(_lineOf(oldImplementation, chainId), newImplementation, chainId);
        string[] memory script = new string[](4);

        script[0] = "diff";
        script[1] = "-ayw";
        script[2] = _getStorageLayoutPath(oldImplementation, chainId);
        script[3] = _getTemporaryStorageLayoutPath(newImplementation);

        bytes memory diff = vm.ffi(script);

        if (diff.length == 0) {
            console2.log(unicode"\nCollision check status: Pass ✅");
            console2.log("\nContract name: %s", contractName);
            console2.log("\nOld: %s <-> New: %s", oldImplementation, newImplementation);
        } else {
            console2.log(unicode"\nCollision check status: Fail ❌");
            console2.log("\nContract name: %s", contractName);
            console2.log("\nOld: %s <-> New: %s", oldImplementation, newImplementation);
            console2.log("\n%s\n", string(diff));
            revert("Contract storage layout changed and might not be compatible.");
        }

        _rmrf(_getTemporaryStorageLayoutPath(newImplementation));
    }

    function _headOf(string memory lineNum, address target, uint256 chainId) internal {
        _mkdir(_basePath("temp/"));

        string[] memory script = new string[](4);
        script[0] = "head";
        script[1] = "-n";
        script[2] = lineNum;
        script[3] = _getStorageLayoutPath(target, chainId);

        bytes memory out = vm.ffi(script);
        vm.writeFile(_getTemporaryStorageLayoutPath(target), string(out));
    }

    function _lineOf(address target, uint256 chainId) internal returns (string memory) {
        string memory path = _getStorageLayoutPath(target, chainId);

        if (!_exist(path)) {
            revert("Not exists file storage layout");
        }

        string[] memory script = new string[](4);
        script[0] = "sed";
        script[1] = "-n";
        script[2] = "$=";
        script[3] = path;

        bytes memory lines = vm.ffi(script);
        return string(lines);
    }

    function _mkdir(string memory path) internal {
        if (__madeDir[path]) return;

        string[] memory script = new string[](3);
        script[0] = "mkdir";
        script[1] = "-p";
        script[2] = path;

        vm.ffi(script);

        __madeDir[path] = true;
    }

    function _rmrf(string memory path) internal {
        string[] memory script = new string[](3);
        script[0] = "rm";
        script[1] = "-rf";
        script[2] = path;

        vm.ffi(script);
    }

    function _exist(string memory file) internal returns (bool exists) {
        string[] memory script = new string[](2);
        script[0] = "ls";
        script[1] = file;

        try vm.ffi(script) returns (bytes memory res) {
            if (bytes(res).length != 0) {
                exists = true;
            }
        } catch { }
    }

    function _basePath(string memory path) internal pure returns (string memory) {
        return string.concat("deployments/", path);
    }

    function _getStorageLayoutPath(address implementation, uint256 chainId) internal pure returns (string memory) {
        return _basePath(
            string.concat("storage/", vm.toString(chainId), "/", vm.toString(implementation), ".storage-layout")
        );
    }

    function _getTemporaryStorageLayoutPath(address implementation) internal pure returns (string memory) {
        return _basePath(string.concat("temp/", vm.toString(implementation), ".temp"));
    }
}
