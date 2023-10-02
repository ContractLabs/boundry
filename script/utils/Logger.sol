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

    function _deploymentLogs(
        address proxy,
        address implementation,
        string memory contractName,
        uint256 chainId
    )
        internal
    {
        _mkdir(_getChainFolderPath(chainId, ""));

        string memory filePath = _getContractLogPath(contractName, chainId);
        string memory format = _baseFormatJson(implementation, contractName);

        // non-proxy logs
        if (proxy == address(0)) {
            if (_fileExists(filePath)) {
                _mv(
                    filePath, string.concat(filePath, _getContractLogPath(string.concat(contractName, "-old"), chainId))
                );
            }
            vm.writeJson(format, filePath);
        }
        // proxy logs
        else {
            if (!_fileExists(filePath)) {
                string memory init = string.concat(
                    '{"proxy": "',
                    vm.toString(proxy),
                    '", "implementations": {',
                    '"0": {},',
                    '"1": {},',
                    '"2": {},',
                    '"3": {},',
                    '"4": {},',
                    '"5": {},',
                    '"6": {},',
                    '"7": {},',
                    '"8": {},',
                    '"9": {},',
                    '"10": {},',
                    '"11": {},',
                    '"12": {},',
                    '"13": {},',
                    '"14": {},',
                    '"15": {},',
                    '"16": {},',
                    '"17": {},',
                    '"18": {},',
                    '"19": {},',
                    '"20": {},',
                    '"21": {},',
                    '"22": {},',
                    '"23": {},',
                    '"24": {},',
                    '"25": {},',
                    '"26": {},',
                    '"27": {},',
                    '"28": {},',
                    '"29": {},',
                    '"30": {}',
                    '}}'
                );
                vm.writeJson(init, filePath);
                vm.writeJson(format, filePath, string.concat(".implementations.0"));
            } else {
                vm.writeJson(format, filePath, string.concat(".implementations.", _getKeyAvailable(filePath)));
            }
        }
    }

    function _storageLayoutTemp(string memory filePath) internal {
        _mkdir(_getTemporaryStoragePath(""));
        string memory json = vm.readFile(filePath);
        JSONParserLib.Item memory item = json.parse();
        vm.writeFile(
            _getTemporaryStoragePath("latest.storage-layout"), _getLatestStorageLayout(item.children()[1]).value()
        );
        vm.writeLine(_getTemporaryStoragePath("latest.storage-layout"), "");
        vm.writeFile(
            _getTemporaryStoragePath("previous.storage-layout"),
            _getPreviousLatestStorageLayout(item.children()[1]).value()
        );
        vm.writeLine(_getTemporaryStoragePath("previous.storage-layout"), "");
    }

    function _getKeyAvailable(string memory filePath) internal view returns (string memory keyAvailable) {
        string memory json = vm.readFile(filePath);
        JSONParserLib.Item memory item = json.parse().children()[1];
        uint256 length = item.size();

        for (uint256 i; i < length; ++i) {
            if (_areStringsEqual(item.children()[i].value(), "{}")) {
                return item.children()[i].key().replace('"', "");
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

    function _getLatestImplementation(JSONParserLib.Item memory item) internal pure returns (address impl) {
        uint256 length = item.size();

        for (uint256 i = length - 1; i >= 0; --i) {
            if (!_areStringsEqual(item.children()[i].value(), "{}")) {
                return vm.parseAddress(item.children()[i].children()[0].value());
            }
        }
    }

    function _getContractAddress(string memory contractName, uint256 chainId) internal view returns (address) {
        string memory json = vm.readFile(_getContractLogPath(contractName, chainId));
        JSONParserLib.Item memory item = json.parse();
        return vm.parseAddress(item.children()[0].value());
    }

    function _getLatestStorageLayout(JSONParserLib.Item memory item)
        internal
        pure
        returns (JSONParserLib.Item memory storageLayout)
    {
        uint256 length = item.size();

        for (uint256 i = length - 1; i >= 0; --i) {
            if (!_areStringsEqual(item.children()[i].value(), "{}")) {
                return item.children()[i].children()[1];
            }
        }
    }

    function _getLatestStorageLayoutKey(JSONParserLib.Item memory item) internal pure returns (string memory key) {
        uint256 length = item.size();

        for (uint256 i = length - 1; i >= 0; --i) {
            if (!_areStringsEqual(item.children()[i].value(), "{}")) {
                return item.children()[i].children()[1].key().replace('"', "");
            }
        }
    }

    function _getPreviousLatestStorageLayout(JSONParserLib.Item memory item)
        internal
        pure
        returns (JSONParserLib.Item memory storageLayout)
    {
        uint256 length = item.size();

        for (uint256 i = length - 1; i >= 0; --i) {
            if (!_areStringsEqual(item.children()[i].value(), "{}")) {
                return item.children()[i - 1].children()[1];
            }
        }
    }

    function _overrideNullStorageLayout(string memory path) internal {
        JSONParserLib.Item memory item = vm.readFile(path).parse();
        string memory key = _getLatestStorageLayoutKey(item);
        vm.writeJson("{}", path, string.concat(".implementations.", key));
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

    function _rmrf(string memory path) internal {
        string[] memory script = new string[](3);
        script[0] = "rm";
        script[1] = "-rf";
        script[2] = path;

        vm.ffi(script);
    }

    function _fileExists(string memory file) internal returns (bool exists) {
        string[] memory script = new string[](2);
        script[0] = "ls";
        script[1] = file;

        try vm.ffi(script) returns (bytes memory res) {
            if (bytes(res).length != 0) {
                exists = true;
            }
        } catch { }
    }

    function _areStringsEqual(string memory firstStr, string memory secondStr) internal pure returns (bool) {
        return keccak256(abi.encodePacked(firstStr)) == keccak256(abi.encodePacked(secondStr));
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

    function _getTemporaryStoragePath(string memory path) internal pure returns (string memory) {
        return string.concat("temp/", path);
    }
}
