// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract CounterUpgradeable is Initializable, UUPSUpgradeable, ERC20Upgradeable {
    struct A {
        uint256 a;
        bool b;
        bool d;
        bool e;
        bool f;
        bytes32 c;
    }

    uint256 public number;
    A private a;
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
