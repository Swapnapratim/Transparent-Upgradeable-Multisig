// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/MyLogicContract.sol";
import "../src/TransparentUpgradeableProxy.sol";

contract DeployScript is Script {
    function run() external {
        address deployer = vm.envAddress("DEPLOYER_KEY");
        vm.startBroadcast(deployer);

        // Step 1: Deploy Logic Contract
        MyLogicContract logicContract = new MyLogicContract();
        console.log("Logic Contract deployed at:", address(logicContract));

        // Step 2: Deploy Transparent Upgradeable Proxy
        address admin = deployer; // Deployer is the admin for simplicity
        bytes memory data = abi.encodeWithSelector(MyLogicContract.setValue.selector, 42); // Example initialization data

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(logicContract),
            admin,
            data
        );
        console.log("Proxy Contract deployed at:", address(proxy));

        vm.stopBroadcast();
    }
}
