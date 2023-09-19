// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Counter } from "src/Counter.sol";
import { Script, console2 } from "forge-std/Script.sol";

contract CounterScript is Script {
    function setUp() public {}

    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address deployAddress = vm.addr(privateKey);

        console2.log("Deployer: ", deployAddress);

        vm.startBroadcast(privateKey);
        // deploy
        Counter counter = new Counter(0);
        // counter.setNumber(0);
        vm.stopBroadcast();
    }
}
