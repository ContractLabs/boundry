// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

// forgefmt: disable-start
import { 
    console2,
    BaseScript 
} from "./Base.s.sol";

import { 
    IUpgradeableProxy 
} from "script/interfaces/IUpgradeableProxy.sol";

import { 
    ERC1967Proxy 
} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import { 
    ProxyAdmin 
} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

import {
    ITransparentUpgradeableProxy,
    TransparentUpgradeableProxy
} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
// forgefmt: disable-end

enum Kind {
    Uups,
    Transparent,
    NonProxy
}

struct Result {
    address proxyOrDeployed;
    address logic;
    Kind kind;
}

abstract contract BaseDeploy is BaseScript {
    address $admin;
    Kind internal kind;
    bytes internal EMPTY_ARGS;

    function overrideAdmin(address admin_) public {
        $admin = admin_;
    }

    function admin() public returns (address _admin) {
        _admin = $admin == address(0) ? _defaultAdmin() : $admin;
    }

    function switchKind(Kind kind_) public {
        kind = kind_;
        console2.log("Current proxy kind: ", uint8(kind));
    }

    function _defaultAdmin() internal virtual returns (address _admin) { }

    function deployRaw(
        string memory filename,
        bytes memory args
    )
        public
        returns (address payable deployed)
    {
        vm.resumeGasMetering();
        deployed = payable(deployCode(filename, args));
        vm.pauseGasMetering();
    }

    function deployLogic(string memory filename)
        public
        returns (address payable deployed)
    {
        deployed = deployRaw(filename, EMPTY_ARGS);
    }

    function upgradeRaw(
        address payable proxy,
        address logic,
        bytes memory args
    )
        public
    {
        if (kind == Kind.Uups) {
            _uupsUpgrade(proxy, logic, args);
        }
        if (kind == Kind.Transparent) {
            _transparentUpgrade(proxy, logic, args);
        }
    }

    function upgradeTo(address payable proxy, address logic) public {
        upgradeRaw(proxy, logic, EMPTY_ARGS);
    }

    function deployProxyRaw(
        string memory filename,
        bytes memory args
    )
        public
        returns (address payable proxy)
    {
        address logic = deployRaw(filename, "");

        if (kind == Kind.Uups) {
            proxy = deployRaw(
                "ERC1967Proxy.sol:ERC1967Proxy", abi.encode(logic, args)
            );
        }
        if (kind == Kind.Transparent) {
            proxy = deployRaw(
                "TransparentUpgradeableProxy.sol:TransparentUpgradeableProxy",
                abi.encode(logic, admin(), args)
            );
        }
    }

    function _uupsUpgrade(
        address payable proxy,
        address logic,
        bytes memory args
    )
        internal
    {
        vm.resumeGasMetering();
        IUpgradeableProxy(proxy).upgradeToAndCall(logic, args);
        vm.pauseGasMetering();
    }

    function _transparentUpgrade(
        address payable proxy,
        address logic,
        bytes memory args
    )
        internal
    {
        address owner = ProxyAdmin(admin()).owner();
        require(owner == msg.sender, "deployer != owner of ProxyAdmin");

        vm.resumeGasMetering();
        proxy = deployRaw(
            "TransparentUpgradeableProxy.sol:TransparentUpgradeableProxy",
            abi.encode(logic, admin(), args)
        );
        vm.pauseGasMetering();
    }
}
