// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./migrations/BaseScript.s.sol";

import { SampleUUPS } from "src/Sample.sol";

contract UpgradeScript is BaseScript {
    function run() public returns (address proxy, address implementation) {
        vm.startBroadcast(vm.envUint("DEPLOYER_PRIVATE_KEY"));
        (proxy, implementation) = upgradeTo(type(SampleUUPS).name);
        vm.stopBroadcast();
    }
}
