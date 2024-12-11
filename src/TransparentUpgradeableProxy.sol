// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract TransparentUpgradeableProxy {
    // Define storage slot constants as per ERC-1967
    bytes32 private constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    bytes32 private constant _ADMIN_SLOT =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    event Upgraded(address indexed newImplementation);
    event AdminChanged(address indexed previousAdmin, address indexed newAdmin);

    constructor(address implementation, address adminAddress, bytes memory data) {
        require(implementation != address(0), "Implementation cannot be zero address");
        require(adminAddress != address(0), "Admin cannot be zero address");

        _setImplementation(implementation);
        _setAdmin(adminAddress);

        if (data.length > 0) {
            (bool success, ) = implementation.delegatecall(data);
            require(success, "Initialization failed");
        }
    }

    fallback() external payable {
        _delegate(_getImplementation());
    }

    receive() external payable {
        _delegate(_getImplementation());
    }

    function admin() public view returns (address adm) {
        return _getAdmin();
    }

    function upgradeTo(address newImplementation) external {
        require(msg.sender == _getAdmin(), "Caller is not admin");
        require(newImplementation != address(0), "Implementation cannot be zero address");

        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    function changeAdmin(address newAdmin) external {
        require(msg.sender == _getAdmin(), "Caller is not admin");
        require(newAdmin != address(0), "New admin cannot be zero address");

        address previousAdmin = _getAdmin();
        _setAdmin(newAdmin);
        emit AdminChanged(previousAdmin, newAdmin);
    }

    function _getImplementation() private view returns (address) {
        return _getAddress(_IMPLEMENTATION_SLOT);
    }

    function _getAdmin() private view returns (address) {
        return _getAddress(_ADMIN_SLOT);
    }

    function _setImplementation(address newImplementation) private {
        _setAddress(_IMPLEMENTATION_SLOT, newImplementation);
    }

    function _setAdmin(address newAdmin) private {
        _setAddress(_ADMIN_SLOT, newAdmin);
    }

    function _getAddress(bytes32 slot) private view returns (address addr) {
        assembly {
            addr := sload(slot)
        }
    }

    function _setAddress(bytes32 slot, address value) private {
        assembly {
            sstore(slot, value)
        }
    }

    function _delegate(address implementation) private {
        assembly {
            // Copy calldata to memory
            calldatacopy(0, 0, calldatasize())
            // Perform delegatecall
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)
            // Copy returndata to memory
            returndatacopy(0, 0, returndatasize())
            // Check result and revert or return accordingly
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}
