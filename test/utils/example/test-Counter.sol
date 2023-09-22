// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "test/Counter.t.sol";

import { Counter } from "src/example/Counter.sol";

contract TestCounter is CounterTest {
    Counter public counter;

    function _setUp() internal override {
        counter = new Counter(0);
    }

    function test_Increment() public {
        counter.increment();
        assertEq(counter.number(), 1);
    }

    function testFuzz_SetNumber(uint256 x) public {
        counter.setNumber(x);
        assertEq(counter.number(), x);
    }
}
