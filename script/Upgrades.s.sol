// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Counter } from "src/example/Counter.sol";
import { Script, console2 } from "forge-std/Script.sol";
import { CounterUpgradeable } from "src/example/CounterUpgradeable.sol";
import { CounterUpgradeableV2 } from "src/example/CounterUpgradeableV2.sol";
import { ERC1967Proxy } from
    "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { TransparentUpgradeableProxy } from
    "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract UpgradesScript is Script {
    mapping(string => bool) __madeDir;
    mapping(uint256 => mapping(address => bool)) __storageLayoutGenerated;

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

    function run() public {
        // deploy("Counter");
        // deployUupsProxy("CounterUpgradeable");
        // deployTransparentProxy("CounterUpgradeableV2");
        upgrade();
    }

    function deploy(string memory contractName) public {
        vm.startBroadcast(setUpDeployer());
        address addr = address(new Counter(0));
        vm.stopBroadcast();
        generateStorageLayoutFile(contractName, addr);
    }

    function deployUupsProxy(string memory contractName) public {
        vm.startBroadcast(setUpDeployer());
        address logic = address(new CounterUpgradeable());
        address proxy = address(
            new ERC1967Proxy(logic, abi.encodeCall(CounterUpgradeable.initialize,(0)))
        );
        CounterUpgradeable _contract = CounterUpgradeable(payable(proxy));
        vm.stopBroadcast();
        generateStorageLayoutFile(contractName, logic);
    }

    function deployTransparentProxy(string memory contractName) public {
        vm.startBroadcast(setUpDeployer());
        address logic = address(new CounterUpgradeableV2());
        address proxy = address(
            new TransparentUpgradeableProxy(logic, vm.addr(setUpDeployer()), abi.encodeCall(CounterUpgradeableV2.initialize, (0)))
        );
        CounterUpgradeableV2 _contract = CounterUpgradeableV2(payable(proxy));
        vm.stopBroadcast();
        generateStorageLayoutFile(contractName, logic);
    }

    function upgrade() public {
        address oldImpl = 0xD4ab9D3d5C1D788BDfA8cdf3Eb17c0A84E29B737; // parse
            // old impl address here
        CounterUpgradeable proxy = CounterUpgradeable(
            payable(0xA069F0389312b87E9A995E17901CaA93DE8b09aD)
        );
        vm.startBroadcast(setUpUpgrader());
        address newImpl = address(new CounterUpgradeable()); // change contract
            // here
        generateStorageLayoutFile("CounterUpgradeable", newImpl);
        checkStorage("CounterUpgradeable", oldImpl, newImpl);
        proxy.upgradeTo(newImpl);
        vm.stopBroadcast();
        rmrf(getCacheStorageLayoutFilePath(newImpl));
    }

    // ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ FOR NORMAL USAGE NOT CONFIG ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇
    function generateStorageLayoutFile(
        string memory contractName,
        address implementation
    )
        internal
    {
        if (__storageLayoutGenerated[block.chainid][implementation]) return;

        console2.log(
            "Generating storage layout mapping for %s.\n",
            contractName,
            implementation
        );

        // mkdir if not already
        mkdir(getDeploymentsPath("data/"));

        string[] memory script = new string[](5);
        script[0] = "forge";
        script[1] = "inspect";
        script[2] = contractName;
        script[3] = "storage-layout";
        script[4] = "--pretty";
        bytes memory out = vm.ffi(script);

        vm.writeFile(getStorageLayoutFilePath(implementation), string(out));

        __storageLayoutGenerated[block.chainid][implementation] = true;
    }
    // utils

    function checkStorage(
        string memory contractName,
        address oldImpl,
        address newImpl
    )
        internal
    {
        string memory lines = countLines(oldImpl);
        headOfLines(
            lines,
            getStorageLayoutFilePath(newImpl),
            getCacheStorageLayoutFilePath(newImpl)
        );

        string[] memory script = new string[](4);

        script[0] = "diff";
        script[1] = "-ayw";
        script[2] = getStorageLayoutFilePath(oldImpl);
        script[3] = getCacheStorageLayoutFilePath(newImpl);

        bytes memory diff = vm.ffi(script);

        if (diff.length == 0) {
            console2.log(unicode"\nStorage layout compatibility check: ✅");
            console2.log(
                "\nContract name: %s - Execute time: %s",
                contractName,
                vm.toString(block.timestamp)
            );
            console2.log("\n[Old: %s <-> New: %s]", oldImpl, newImpl);
        } else {
            console2.log(unicode"\nStorage layout compatibility check: ❌");
            console2.log(
                "\nContract name: %s - Execute time: %s",
                contractName,
                vm.toString(block.timestamp)
            );
            console2.log("\n[Old: %s <-> New: %s]", oldImpl, newImpl);
            console2.log("\n%s\n", string(diff));
            revert(
                "Contract storage layout changed and might not be compatible."
            );
        }
    }

    function countLines(address implementation)
        internal
        returns (string memory)
    {
        if (!fileExists(getStorageLayoutFilePath(implementation))) {
            revert("Not exists file storage layout");
        }
        string[] memory script = new string[](4);
        script[0] = "sed";
        script[1] = "-n";
        script[2] = "$=";
        script[3] = getStorageLayoutFilePath(implementation);

        bytes memory lines = vm.ffi(script);
        return string(lines);
    }

    function headOfLines(
        string memory lines,
        string memory readPath,
        string memory writePath
    )
        internal
    {
        mkdir(getDeploymentsPath("temp/"));

        string[] memory script = new string[](4);

        script[0] = "head";
        script[1] = "-n";
        script[2] = lines;
        script[3] = readPath;

        bytes memory out = vm.ffi(script);
        vm.writeFile(writePath, string(out));
    }

    function mkdir(string memory path) internal {
        if (__madeDir[path]) return;

        string[] memory script = new string[](3);
        script[0] = "mkdir";
        script[1] = "-p";
        script[2] = path;

        vm.ffi(script);

        __madeDir[path] = true;
    }

    function rmrf(string memory path) internal {
        if (!fileExists(path)) return;

        string[] memory script = new string[](3);
        script[0] = "rm";
        script[1] = "-rf";
        script[2] = path;

        vm.ffi(script);
    }

    function fileExists(string memory file) internal returns (bool exists) {
        string[] memory script = new string[](2);
        script[0] = "ls";
        script[1] = file;

        try vm.ffi(script) returns (bytes memory res) {
            if (bytes(res).length != 0) {
                exists = true;
            }
        } catch { }
    }

    // filePath
    function getDeploymentsPath(string memory path)
        internal
        returns (string memory)
    {
        return getDeploymentsPath(path, block.chainid);
    }

    function getDeploymentsPath(
        string memory path,
        uint256 chainId
    )
        internal
        returns (string memory)
    {
        return string.concat("deployments/", vm.toString(chainId), "/", path);
    }

    function getStorageLayoutFilePath(address addr)
        internal
        returns (string memory)
    {
        return getDeploymentsPath(
            string.concat("data/", vm.toString(addr), ".storage-layout")
        );
    }

    function getCacheStorageLayoutFilePath(address addr)
        internal
        returns (string memory)
    {
        return getDeploymentsPath(
            string.concat("temp/", vm.toString(addr), ".storage-layout")
        );
    }

    // ⬆⬆⬆⬆⬆⬆⬆⬆⬆⬆⬆⬆⬆⬆⬆⬆⬆⬆⬆ FOR NORMAL USAGE NOT CONFIG ⬆⬆⬆⬆⬆⬆⬆⬆⬆⬆⬆⬆⬆⬆⬆⬆⬆⬆⬆
}
