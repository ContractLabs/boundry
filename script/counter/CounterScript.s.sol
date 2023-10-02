// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { BaseScript, console2 } from "script/BaseScript.s.sol";
import { CounterUpgradeable } from "src/example/CounterUpgradeable.sol";
import { CounterUpgradeableV2 } from "src/example/CounterUpgradeableV2.sol";

contract CounterScript is BaseScript {
    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        // deployUups();
        // deployTransparent();
        upgradeTo(true);
        // upgradeToAndCall();
        vm.stopBroadcast();
    }

    function admin() public view override returns (address) {
        return vm.addr(vm.envUint("PRIVATE_KEY"));
    }

    function deployUups() public {
        address payable proxy =
            _deployProxyRaw(type(CounterUpgradeable).name, abi.encodeCall(CounterUpgradeable.initialize, 0), "uups");
        CounterUpgradeable deployment = CounterUpgradeable(proxy);
    }

    function deployTransparent() public {
        address payable proxy = _deployProxyRaw(
            type(CounterUpgradeableV2).name, abi.encodeCall(CounterUpgradeableV2.initialize, 0), "transparent"
        );
        CounterUpgradeableV2 deployment = CounterUpgradeableV2(proxy);
    }

    function upgradeTo(bool skip) public {
        address proxy = 0x8C55dAD338C0c04A8B4F52224bA8D2DDeA430338;
        _upgradeTo(proxy, type(CounterUpgradeableV2).name, skip);
    }

    function upgradeToAndCall(bool skip) public {
        address proxy = 0x21377e21D53A387aBc1485D9B96b7F322fc39352;
        bytes memory data;
        _upgradeToAndCall(proxy, type(CounterUpgradeableV2).name, data, skip);
    }
}
