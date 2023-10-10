// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract CounterUpgradeable is Initializable, UUPSUpgradeable {
    struct Admin {
        bool isAdmin;
        uint8 isSomethingElse;
        bool id;
        uint16 money;
        address walletAddress;
    }

    uint256 public number;
    string public greeting;

    Admin public admin;
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

    function setAdmin(address addr) public {
        admin = Admin(true, 0, true, 0, addr);
    }

    function increment() public {
        number++;
    }

    function setGreeting(string memory greeting_) public {
        greeting = greeting_;
    }

    function _authorizeUpgrade(address) internal override { }
}
