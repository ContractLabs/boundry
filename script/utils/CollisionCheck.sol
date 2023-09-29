// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { console2, LoggerScript } from "script/utils/Logger.sol";
import { JSONParserLib } from "solady/src/utils/JSONParserLib.sol";

contract CollisionCheck is LoggerScript {
    using JSONParserLib for *;

    function _checkForCollision(string memory contractName, uint256 chainId) internal returns (bool) {
        if (!vm.isFile(_getContractLogPath(contractName, chainId))) revert("Deployment contract log file not found.");

        string memory json = vm.readFile(_getContractLogPath(contractName, chainId));
        JSONParserLib.Item memory item = json.parse().children()[1];

        JSONParserLib.Item memory item1 = _getPreviousLatestStorageLayout(item);
        JSONParserLib.Item memory item2 = _getLatestStorageLayout(item);

        for (uint256 i; i < item2.children()[0].size(); ++i) {
            string memory offset = item2.children()[0].children()[i].children()[3].value();
            string memory storageSlot = item2.children()[0].children()[i].children()[4].value();
            string memory typeKey = item2.children()[0].children()[i].children()[5].value();
            string memory numOfBytes = item2.children()[1].at(typeKey).at('"numberOfBytes"').value();
            if (_hasConflict(item1, offset, storageSlot, numOfBytes)) {
                console2.log(
                    string.concat(
                        "\n------------------------------------------------Upcoming implemented storage layout-----------------------------------------------",
                        "\nName: ",
                        item2.children()[0].children()[i].children()[2].value(),
                        "\nOffset: ",
                        offset,
                        "\nType: ",
                        typeKey,
                        "\nBytes: ",
                        numOfBytes,
                        "\n=================================================================================================================================="
                    )
                );
                return false;
            }
        }
        return true;
    }

    function _hasConflict(
        JSONParserLib.Item memory item,
        string memory offset,
        string memory storageSlot,
        string memory numOfBytes
    )
        internal
        pure
        returns (bool)
    {
        for (uint256 i; i < item.children()[0].size(); ++i) {
            string memory _offset = item.children()[0].children()[i].children()[3].value();
            string memory _storageSlot = item.children()[0].children()[i].children()[4].value();
            string memory _typeKey = item.children()[0].children()[i].children()[5].value();
            string memory _numOfBytes = item.children()[1].at(_typeKey).at('"numberOfBytes"').value();

            if (_areStringsEqual(storageSlot, _storageSlot) && _areStringsEqual(offset, _offset)) {
                if (!_areStringsEqual(numOfBytes, _numOfBytes)) {
                    console2.log(
                        string.concat(
                            "\n| Slot: ",
                            _storageSlot,
                            " |",
                            "\n------------------------------------------------Current implemented storage layout------------------------------------------------",
                            "\nName: ",
                            item.children()[0].children()[i].children()[2].value(),
                            "\nOffset: ",
                            _offset,
                            "\nType: ",
                            _typeKey,
                            "\nBytes: ",
                            _numOfBytes
                        )
                    );
                    return true;
                }
            }
        }
        return false;
    }
}
