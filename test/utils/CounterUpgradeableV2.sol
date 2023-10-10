// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract CounterUpgradeableV2 is Initializable {
    uint256 public number;
    string public greeting;

    /// @custom:oz-upgrades-unsafe-allow constructor

    constructor() {
        _disableInitializers();
    }

    function initialize(uint256 number_) public initializer {
        setNumber(number_);
    }

    function setGreeting(string memory greeting_) public {
        greeting = greeting_;
    }

    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }

    function increment() public {
        number++;
    }
}
