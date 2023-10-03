// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.17 <0.9.0;

import { StdCheats } from "forge-std/StdCheats.sol";

import { Assertions } from "test/utils/Assertions.sol";
import { Utils } from "test/utils/Utils.sol";

abstract contract Base_Test is Assertions, Utils, StdCheats { }
