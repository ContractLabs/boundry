// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./BaseScript.s.sol";
import { Counter } from "test/BaseScriptTest/utils/Counter.sol";
import { CounterUpgradeable } from "test/BaseScriptTest/utils/CounterUpgradeable.sol";
import { CounterUpgradeableV2 } from "test/BaseScriptTest/utils/CounterUpgradeableV2.sol";

contract UpgradeScript is BaseScript {
    function run() public returns (address proxy, address implementation) {
        vm.startBroadcast(vm.envUint("DEPLOYER_PRIVATE_KEY"));
        // ctr = deployRaw(type(Counter).name, abi.encode(0));
        (proxy, implementation) = upgradeTo(type(CounterUpgradeable).name, "uups");
        vm.stopBroadcast();
    }
}
