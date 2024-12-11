// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/TransparentUpgradeableProxy.sol";
import "../src/MyLogicContract.sol";
import "../src/MultiSigWallet.sol";

contract OwnershipTransferTest is Test {
    TransparentUpgradeableProxy proxy;
    MyLogicContract logic;
    MultiSigWallet wallet;

    address deployer;
    address signer1 = address(0x1);
    address signer2 = address(0x2);
    address signer3 = address(0x3);
    address optionalSigner = address(0x4);

    function setUp() public {
        deployer = address(this);

        // Step 1: Deploy Logic Contract
        logic = new MyLogicContract();

        // Step 2: Deploy Proxy Contract
        bytes memory data = abi.encodeWithSelector(MyLogicContract.setValue.selector, 42);
        proxy = new TransparentUpgradeableProxy(address(logic), deployer, data);

        // Step 3: Deploy Multi-Signature Wallet
        address[4] memory signers = [signer1, signer2, signer3, optionalSigner]; // Allocate memory for the array

        wallet = new MultiSigWallet(signers, 3);
    }

    function testOwnershipTransfer() public {
        // Ensure the proxy admin is initially the deployer
        assertEq(proxy.admin(), deployer);

        // Transfer ownership to the multi-signature wallet
        proxy.changeAdmin(address(wallet));
        assertEq(proxy.admin(), address(wallet));
    }

    function testSetValueWithMultiSig() public {
        // Step 1: Transfer ownership to the multi-signature wallet
        proxy.changeAdmin(address(wallet));

        // Ensure admin is now the multi-signature wallet
        assertEq(proxy.admin(), address(wallet));

        // Step 2: Create a transaction to call `setValue` on the logic contract
        uint256 newValue = 100;
        bytes memory data = abi.encodeWithSelector(MyLogicContract.setValue.selector, newValue);

        vm.prank(signer1);
        uint256 txIndex = wallet.createTransaction(address(proxy), 0, data);

        // Step 3: Approve the transaction by 3 signers
        vm.prank(signer1); // Simulate signer1
        wallet.approveTransaction(txIndex);

        vm.prank(signer2); // Simulate signer2
        wallet.approveTransaction(txIndex);

        vm.prank(signer3); // Simulate signer3
        wallet.approveTransaction(txIndex);

        // Ensure the transaction has enough approvals and is executed
        (address to, uint256 value, bytes memory txData, bool executed, uint256 signatureCount) = wallet.transactions(txIndex);
        assertTrue(executed);
        assertEq(signatureCount, 3);

        // Verify the value was set in the logic contract via the proxy
        uint256 currentValue = MyLogicContract(address(proxy)).value();
        assertEq(currentValue, newValue);
    }
}
