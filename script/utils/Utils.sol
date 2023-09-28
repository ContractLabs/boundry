// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Script, console2 } from "forge-std/Script.sol";
import { JSONParserLib } from "solady/src/utils/JSONParserLib.sol";

contract UtilsScript is Script {
    using JSONParserLib for *;

    mapping(string => bool) __madeDir;
    mapping(uint256 => string) __chainName;
    mapping(uint256 => mapping(address => bool)) __storageLayoutGenerated;

    function setUp() public {
        __chainName[1] = "ethereum";
        __chainName[5] = "goerli";
        __chainName[43_113] = "fuji";
        __chainName[43_113] = "avalanche";
        __chainName[137] = "polygon";
        __chainName[80_001] = "mumbai";
        __chainName[56] = "binance-mainnet";
        __chainName[97] = "binance-testnet";
        __chainName[42_161] = "arbitrum-mainnet";
        __chainName[421_613] = "arbitrum-testnet";
    }

    function run() public virtual {
        _deploymentLog(0xf543747650D81042FE61BE4Fe861311D1865C8e8, "CounterUpgradeable", 97);
    }

    function _storageLayoutLog(string memory contractName, address implement, uint256 chainId) internal {
        if (__storageLayoutGenerated[chainId][implement]) return;

        _mkdir(_basePath(string.concat("storage/", __chainName[chainId])));

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

    function _getContractDataByKey(string memory contractName, string memory key) internal returns (string memory) {
        string[] memory script = new string[](4);
        script[0] = "forge";
        script[1] = "inspect";
        script[2] = contractName;
        script[3] = key;
        bytes memory out = vm.ffi(script);
        return string(out);
    }

    function _deploymentLog(address contractAddress, string memory contractName, uint256 chainId) internal {
        string memory jsonData;
        string memory filePath;
        string memory abiContract = _getContractDataByKey(contractName, "abi");
        string memory metadata = _getContractDataByKey(contractName, "metadata");
        string memory storageLayout = _getContractDataByKey(contractName, "storage-layout");

        _mkdir(_basePath(__chainName[chainId]));
        filePath = _getDeploymentsLogPath(contractName, chainId);
        jsonData = _baseJsonFormat(contractAddress, metadata, abiContract, storageLayout);

        vm.writeJson(jsonData, filePath);
    }

    function _baseJsonFormat(
        address addr,
        string memory metadata,
        string memory abiContract,
        string memory storageLayout
    )
        internal
        pure
        returns (string memory)
    {
        return string.concat(
            '{"address": "',
            vm.toString(addr),
            '",',
            '"storage": ',
            storageLayout,
            ",",
            '"abi": ',
            abiContract,
            ",",
            '"metadata": ',
            metadata,
            "}"
        );
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

    function _getStorageLayoutPath(address implementation, uint256 chainId) internal view returns (string memory) {
        return _basePath(
            string.concat("storage/", __chainName[chainId], "/", vm.toString(implementation), ".storage-layout")
        );
    }

    function _getDeploymentsLogPath(
        string memory contractName,
        uint256 chainId
    )
        internal
        view
        returns (string memory)
    {
        return _basePath(string.concat(__chainName[chainId], "/", contractName, ".json"));
    }

    function _getTemporaryStorageLayoutPath(address implementation) internal pure returns (string memory) {
        return _basePath(string.concat("temp/", vm.toString(implementation), ".temp"));
    }
}
