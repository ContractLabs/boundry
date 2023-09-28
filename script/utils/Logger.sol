// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Script, console2 } from "forge-std/Script.sol";
import { LibString } from "solady/src/utils/LibString.sol";
import { JSONParserLib } from "solady/src/utils/JSONParserLib.sol";

contract LoggerScript is Script {
    using LibString for *;
    using JSONParserLib for *;

    mapping(uint256 => string) __chainName;

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

    function run() public {
        _deploymentLogs(
            0xf543747650D81042FE61BE4Fe861311D1865C8e8,
            0xf343747650D81042fE61BE4FE861311D1865C8e8,
            "CounterUpgradeable",
            56
        );
    }

    function _deploymentLogs(
        address proxy,
        address implementation,
        string memory contractName,
        uint256 chainId
    )
        internal
    {
        if (!vm.isDir(_getChainFolderPath(chainId, ""))) {
            _mkdir(_getChainFolderPath(chainId, ""));
        }

        string memory filePath = _getContractLogPath(contractName, chainId);
        string memory format = _baseFormatJson(implementation, contractName);

        // non-proxy logs
        if (proxy == address(0)) {
            if (vm.isFile(filePath)) {
                _mv(
                    filePath, string.concat(filePath, _getContractLogPath(string.concat(contractName, "-old"), chainId))
                );
            }
            vm.writeJson(format, filePath);
        }
        // proxy logs
        else {
            if (!vm.isFile(filePath)) {
                string memory init =
                    string.concat('{"proxy": "', vm.toString(proxy), '", "implementations": ', format, '}');
                vm.writeJson(init, filePath);
            } else {
                string memory newData =
                    string.concat('{', _getOldImplementations(contractName, chainId), ",", format, '}');
                vm.writeJson(_cleanString(newData), filePath, ".implementations");
            }
        }
    }

    function _getContractDataByOption(
        string memory contractName,
        string memory option
    )
        internal
        returns (string memory)
    {
        string[] memory script = new string[](4);
        script[0] = "forge";
        script[1] = "inspect";
        script[2] = contractName;
        script[3] = option;
        bytes memory out = vm.ffi(script);
        return string(out);
    }

    function _getOldImplementations(
        string memory contractName,
        uint256 chainId
    )
        internal
        view
        returns (string memory)
    {
        JSONParserLib.Item memory item;
        string memory fileContent = vm.readFile(_getContractLogPath(contractName, chainId));
        item = fileContent.parse();

        return item.children()[1].value();
    }

    function _baseFormatJson(address implementation, string memory contractName) internal returns (string memory) {
        string memory abiContract = _getContractDataByOption(contractName, "abi");
        string memory metadata = _getContractDataByOption(contractName, "metadata");
        string memory storageLayout = _getContractDataByOption(contractName, "storage-layout");

        string memory base = string.concat(
            '{"address": "',
            vm.toString(implementation),
            '",',
            '"storageLayout": ',
            storageLayout,
            ",",
            '"abi": ',
            abiContract,
            ",",
            '"metadata": ',
            metadata,
            '}'
        );

        return base;
    }

    function _cleanString(string memory target) internal pure returns (string memory) {
        return target.replace("\n", "").replace(" ", "");
    }

    function _mkdir(string memory path) internal {
        string[] memory script = new string[](3);
        script[0] = "mkdir";
        script[1] = "-p";
        script[2] = path;
        vm.ffi(script);
    }

    function _mv(string memory fromPath, string memory destPath) internal {
        string[] memory script = new string[](3);
        script[0] = "mv";
        script[1] = fromPath;
        script[2] = destPath;
        vm.ffi(script);
    }

    function _getDeploymentsPath(string memory path) internal pure returns (string memory) {
        return string.concat("deployments/", path);
    }

    function _getChainFolderPath(uint256 chainId, string memory path) internal view returns (string memory) {
        return _getDeploymentsPath(string.concat(__chainName[chainId], "/", path));
    }

    function _getContractLogPath(string memory contractName, uint256 chainId) internal view returns (string memory) {
        return _getChainFolderPath(chainId, string.concat(contractName, ".json"));
    }
}
