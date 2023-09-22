// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Base_Test } from "test/Base.t.sol";
import { console } from "forge-std/console.sol";
import "test/utils/Constants.sol";

contract CounterTest is Base_Test {
    function setUp() public {
        _setUp();
    }

    function _setUp() internal virtual { }

    // function _createFolk() internal virtual {}
}
