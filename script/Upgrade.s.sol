// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./BaseScript.s.sol";
import { Counter } from "test/utils/Counter.sol";
import { CounterUpgradeable } from "test/utils/CounterUpgradeable.sol";
import { CounterUpgradeableV2 } from "test/utils/CounterUpgradeableV2.sol";

contract UpgradeScript is BaseScript {
    function run() public returns (address proxy, address implementation) {
        vm.startBroadcast(vm.envUint("DEPLOYER_PRIVATE_KEY"));
        (proxy, implementation) = upgradeTo(type(CounterUpgradeable).name);
        vm.stopBroadcast();
    }
}
