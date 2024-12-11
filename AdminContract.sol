// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TransparentUpgradeableProxy.sol";
import "./MyLogicContract.sol";

contract Admin {
    TransparentUpgradeableProxy public proxy;

    constructor(address initialImplementation) {
        proxy = new TransparentUpgradeableProxy(
            initialImplementation,
            msg.sender,
            ""
        );
    }

    function upgrade(address newImplementation) external {
        proxy.upgradeTo(newImplementation);
    }

    function changeProxyAdmin(address newAdmin) external {
        proxy.changeAdmin(newAdmin);
    }
}
