// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

interface ITransparentUpgradeableProxyDeployer {
    function paramLogic() external view returns (address);

    function paramAdmin() external view returns (address);

    function paramExtraData() external view returns (bytes memory);
}

contract TransparentUpgradeableProxyV3 is TransparentUpgradeableProxy {
    constructor()
        payable
        TransparentUpgradeableProxy(
            ITransparentUpgradeableProxyDeployer(msg.sender).paramLogic(),
            ITransparentUpgradeableProxyDeployer(msg.sender).paramAdmin(),
            ITransparentUpgradeableProxyDeployer(msg.sender).paramExtraData()
        )
    {}
}