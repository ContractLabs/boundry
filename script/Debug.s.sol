// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Script, console2 } from "forge-std/Script.sol";
import { ErrorHandler } from "./utils/ErrorHandler.sol";

contract Debug is Script {
    using ErrorHandler for *;

    function debug(uint256 forkBlock, address from, address to, uint256 value, bytes memory callData) external {
        if (forkBlock != 0) {
            vm.rollFork(forkBlock);
        }
        vm.prank(from);
        (bool success, bytes memory returnOrRevertData) = to.call{ value: value }(callData);
        success.handleRevert(returnOrRevertData);
    }
}
