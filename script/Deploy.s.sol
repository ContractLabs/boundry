// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./BaseScript.s.sol";
import { Counter } from "test/utils/Counter.sol";
import { CounterUpgradeable } from "test/utils/CounterUpgradeable.sol";
import { CounterUpgradeableV2 } from "test/utils/CounterUpgradeableV2.sol";

contract DeployScript is BaseScript {
    /**
     * * @dev For non-proxy deployment, the return value must be `address deployment`,
     * * and for proxy deployment, it should be `address proxy, address implementation, string memory kind`
     */
    function run() public returns (address proxy, address implementation, string memory kind) {
        vm.startBroadcast(vm.envUint("DEPLOYER_PRIVATE_KEY"));
        (proxy, implementation, kind) = _deployUUPS();
        vm.stopBroadcast();
    }

    function _deployCounter() internal returns (address deployment) {
        deployment = deployRaw(type(Counter).name, abi.encode(0));
    }

    function _deployUUPS() internal returns (address proxy, address implementation, string memory kind) {
        (proxy, implementation, kind) =
            deployProxyRaw(type(CounterUpgradeable).name, abi.encodeCall(CounterUpgradeable.initialize, 0), "uups");
    }

    function _deployTransparent() internal returns (address proxy, address implementation, string memory kind) {
        (proxy, implementation, kind) = deployProxyRaw(
            type(CounterUpgradeableV2).name, abi.encodeCall(CounterUpgradeableV2.initialize, 0), "transparent"
        );
    }
}
