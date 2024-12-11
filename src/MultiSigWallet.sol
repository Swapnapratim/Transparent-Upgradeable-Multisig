// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MultiSigWallet {
    address[] public signers;
    uint256 public requiredSignatures;

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 signatureCount;
    }

    mapping(uint256 => mapping(address => bool)) public approvals;
    Transaction[] public transactions;

    event TransactionCreated(uint256 indexed txIndex, address indexed to, uint256 value, bytes data);
    event TransactionApproved(uint256 indexed txIndex, address indexed signer);
    event TransactionExecuted(uint256 indexed txIndex);

    constructor(address[4] memory _signers, uint256 _requiredSignatures) {
        require(_signers.length == 4, "Must have exactly 4 signers");
        require(_requiredSignatures <= 3, "Max required signatures is 3");
        require(_requiredSignatures >= 1, "Min required signatures is 1");

        signers = _signers;
        requiredSignatures = _requiredSignatures;
    }

    modifier onlySigner() {
        require(isSigner(msg.sender), "Not a signer");
        _;
    }

    function isSigner(address account) public view returns (bool) {
        for (uint256 i = 0; i < signers.length; i++) {
            if (signers[i] == account) {
                return true;
            }
        }
        return false;
    }

    function createTransaction(address to, uint256 value, bytes memory data) external onlySigner returns (uint256) {
        transactions.push(Transaction({to: to, value: value, data: data, executed: false, signatureCount: 0}));
        emit TransactionCreated(transactions.length - 1, to, value, data);
        return transactions.length - 1;
    }

    function approveTransaction(uint256 txIndex) external onlySigner {
        require(txIndex < transactions.length, "Invalid transaction index");
        Transaction storage txn = transactions[txIndex];

        require(!txn.executed, "Transaction already executed");
        require(!approvals[txIndex][msg.sender], "Transaction already approved by this signer");

        approvals[txIndex][msg.sender] = true;
        txn.signatureCount++;

        emit TransactionApproved(txIndex, msg.sender);

        if (txn.signatureCount >= requiredSignatures) {
            _executeTransaction(txIndex);
        }
    }

    function _executeTransaction(uint256 txIndex) private {
        Transaction storage txn = transactions[txIndex];
        require(!txn.executed, "Transaction already executed");
        require(txn.signatureCount >= requiredSignatures, "Not enough signatures");

        txn.executed = true;
        (bool success, ) = txn.to.call{value: txn.value}(txn.data);
        require(success, "Transaction execution failed");

        emit TransactionExecuted(txIndex);
    }

    receive() external payable {}
}
