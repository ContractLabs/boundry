// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Script, console2 } from "forge-std/Script.sol";
import { JSONParserLib } from "solady/src/utils/JSONParserLib.sol";

contract CollisionCheck is Script {
    using JSONParserLib for *;

    function run() public {
        checkForCollision("test.json", "test2.json");
    }

    function checkForCollision(string memory path1, string memory path2) internal returns (bool) {
        JSONParserLib.Item memory item1 = getStorageLayoutItems(path1);
        JSONParserLib.Item memory item2 = getStorageLayoutItems(path2);

        if (!areStringsEqual(item1.at('"contract"').value(), item2.at('"contract"').value())) {
            return false;
        }

        for (uint256 i; i < item2.children()[0].size(); ++i) {
            string memory offset = item2.children()[0].children()[i].children()[3].value();
            string memory storageSlot = item2.children()[0].children()[i].children()[4].value();
            string memory typeKey = item2.children()[0].children()[i].children()[5].value();
            string memory numOfBytes = item2.children()[1].at(typeKey).at('"numberOfBytes"').value();

            if (hasConflict(item1, offset, storageSlot, numOfBytes)) {
                console2.log(
                    string.concat(
                        "\n-----------------------------------------------Upcoming implemented storage layout-----------------------------------------------",
                        "\nName: ",
                        item2.children()[0].children()[i].children()[2].value(),
                        "\nOffset: ",
                        offset,
                        "\nType: ",
                        typeKey,
                        "\nBytes: ",
                        numOfBytes,
                        "\n================================================================================================================================"
                    )
                );
            }
        }
    }

    function hasConflict(
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

            if (areStringsEqual(storageSlot, _storageSlot) && areStringsEqual(offset, _offset)) {
                if (!areStringsEqual(numOfBytes, _numOfBytes)) {
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

    function getStorageLayoutItems(string memory jsonPath) internal view returns (JSONParserLib.Item memory) {
        string memory contents = vm.readFile(jsonPath);
        return contents.parse().children()[2];
    }

    function areStringsEqual(string memory str1, string memory str2) internal pure returns (bool) {
        return keccak256(abi.encodePacked(str1)) == keccak256(abi.encodePacked(str2));
    }
}
