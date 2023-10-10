// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

contract Counter {
    uint256 public number;

    constructor(uint256 num) {
        setNumber(num);
    }

    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }

    function increment() public {
        number++;
    }
}
