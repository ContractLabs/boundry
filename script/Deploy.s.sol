// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./migrations/BaseScript.s.sol";

import { Sample, SampleUUPS, SampleTransparent } from "src/Sample.sol";

contract DeployScript is BaseScript {
    /**
     * * @dev For non-proxy deployment, the return value must be `address deployment`,
     * * and for proxy deployment, it should be `address proxy, address implementation, string memory kind`
     */
    function run() public returns (address proxy, address implementation, string memory kind) {
        // returns (address deployment) {
        vm.startBroadcast(vm.envUint("DEPLOYER_PRIVATE_KEY"));
        //deployment = _deploySample();
        (proxy, implementation, kind) = _deployTransparent(); //_deployUUPS();
        vm.stopBroadcast();
    }

    // override because contract name and contract file name are not same
    function contractFile() public pure override returns (string memory) {
        return "Sample.sol";
    }

    // for transparent deployment
    function getAdmin() public pure override returns (address) {
        return 0x58f5663cCb305366F584b5f4dF523728D5479396;
    }

    function _deploySample() internal returns (address deployment) {
        deployment = deployRaw(type(Sample).name, _EMPTY_PARAMS);
    }

    function _deployUUPS() internal returns (address proxy, address implementation, string memory kind) {
        (proxy, implementation, kind) =
            deployProxyRaw(type(SampleUUPS).name, abi.encodeCall(SampleUUPS.initialize, ()), "uups");
    }

    function _deployTransparent() internal returns (address proxy, address implementation, string memory kind) {
        (proxy, implementation, kind) = deployProxyRaw(
            type(SampleTransparent).name, abi.encodeCall(SampleTransparent.initialize, ()), "transparent"
        );
    }
}
