// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Initializable } from
    "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from
    "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract CounterUpgradeable is Initializable, UUPSUpgradeable {
    uint256 public number;
    string public greeting;
    /// @custom:oz-upgrades-unsafe-allow constructor

    constructor() {
        _disableInitializers();
    }

    function initialize(uint256 number_) public initializer {
        __UUPSUpgradeable_init();
        setNumber(number_);
    }

    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }

    function increment() public {
        number++;
    }

    function setGreeting(string memory greeting_) public {
        greeting = greeting_;
    }

    function _authorizeUpgrade(address) internal override { }
}