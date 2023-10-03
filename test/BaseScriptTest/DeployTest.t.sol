// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { console2, Test } from "forge-std/Test.sol";
import { BaseScript } from "script/BaseScript.s.sol";

import { Counter } from "./utils/Counter.sol";
import { CounterUpgradeable } from "./utils/CounterUpgradeable.sol";
import { CounterUpgradeableV2 } from "./utils/CounterUpgradeableV2.sol";
import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

contract DeployTest is Test {
    BaseScript public script;
    bytes public constant EMPTY_PARAMS = "";

    function setUp() public {
        script = new BaseScript();
    }

    function testNormalDeploy() public {
        address deployment = script.deployRaw(type(Counter).name, abi.encode(0));
        address deploymentInLog = script.getContractAddress(type(Counter).name, block.chainid);
        assertEq(address(deployment), address(deploymentInLog));
    }

    function testUUPSProxyDeploy() public {
        address proxy = script.deployProxyRaw(
            type(CounterUpgradeable).name, abi.encodeCall(CounterUpgradeable.initialize, 0), "uups"
        );
        CounterUpgradeable deployment = CounterUpgradeable(proxy);
        address deploymentInLog = script.getContractAddress(type(CounterUpgradeable).name, block.chainid);
        assertEq(address(deployment), address(deploymentInLog));
    }

    function testTransparentProxyDeploy() public {
        script.deployRaw(type(ProxyAdmin).name, EMPTY_PARAMS);
        address proxy = script.deployProxyRaw(
            type(CounterUpgradeableV2).name, abi.encodeCall(CounterUpgradeableV2.initialize, 0), "transparent"
        );
        CounterUpgradeableV2 deployment = CounterUpgradeableV2(proxy);
        address deploymentInLog = script.getContractAddress(type(CounterUpgradeableV2).name, block.chainid);
        assertEq(address(deployment), address(deploymentInLog));
    }

    // function _testUupsProxyUpgrade() internal {
    //     address oldImpl = script.getLatestImplementationAddress(type(CounterUpgradeable).name, block.chainid);
    //     address proxy = script.getContractAddress(type(CounterUpgradeable).name, block.chainid);
    //     // You should make sure that the last parameter is set to 'false'
    //     // first to ensure that the slot does not collide with the old slot.
    //     script.upgradeTo(proxy, type(CounterUpgradeable).name, "uups", true);
    //     address newImpl = script.getLatestImplementationAddress(type(CounterUpgradeable).name, block.chainid);

    //     assertFalse(oldImpl == newImpl);
    // }

    // function _testTransparentProxyUpgrade() internal {
    //     address oldImpl = script.getLatestImplementationAddress(type(CounterUpgradeableV2).name, block.chainid);
    //     address proxy = script.getContractAddress(type(CounterUpgradeableV2).name, block.chainid);
    //     // You should make sure that the last parameter is set to 'false'
    //     // first to ensure that the slot does not collide with the old slot.
    //     script.upgradeTo(proxy, type(CounterUpgradeableV2).name, "transparent", true);
    //     address newImpl = script.getLatestImplementationAddress(type(CounterUpgradeableV2).name, block.chainid);

    //     assertFalse(oldImpl == newImpl);
    // }
}
