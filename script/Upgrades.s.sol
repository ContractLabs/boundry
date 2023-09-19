// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Script, console2 } from "forge-std/Script.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract UpgradesScript is Script {
    function setUpDeployer() public view returns (uint256) {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        console2.log(vm.addr(privateKey), "Deployer: ");
        return privateKey;
    }

    function setUpUpgrader() public view returns (uint256) {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        console2.log(vm.addr(privateKey), "Upgrader: ");
        return privateKey;
    }

    function deploy() public {
        vm.startBroadcast(setUpDeployer());
        vm.stopBroadcast();
    }

    function deployUupsProxy() public {
        vm.startBroadcast(setUpDeployer());
        // address logic = address(new ContractWantToDeploy());
        // address proxy = address(new ERC1967Proxy(logic, abi.encodeCall(ContractWantToDeploy.initialize, (params...))));
        // ContractWantToDeploy _contract = ContractWantToDeploy(payable(proxy));
        vm.stopBroadcast();
    }

    function deployTransparentProxy() public {
        vm.startBroadcast(setUpDeployer());
        // address logic = address(new ContractWantToDeploy());
        // address proxy = address(new TransparentUpgradeableProxy(logic, initAdmin, abi.encodeCall(ContractWantToDeploy.initialize, (params...))));
        // ContractWantToDeploy _contract = ContractWantToDeploy(payable(proxy));
        vm.stopBroadcast();
    }
    function upgrade() public {
        address contractToUpgrade;
        vm.startBroadcast(setUpUpgrader());
        // address newLogic = address(new ContractWantToUpgrade())
        // contractToUpgrade.upgradeToAndCall(newLogic, bytes(""));
        vm.stopBroadcast();
    }
    function run() public {}
}