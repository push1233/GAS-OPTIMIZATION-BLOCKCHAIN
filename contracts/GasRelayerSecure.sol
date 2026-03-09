// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

contract GasRelayer is EIP712 {
    using ECDSA for bytes32;

    
    mapping(address => uint256) public nonces;

    
    mapping(address => uint256) public balances;

    
    struct MetaTransaction {
        address user;
        address recipient;
        uint256 amount;
        uint256 nonce;
    }

    
    event TransferSuccess(address indexed user, address indexed recipient, uint256 amount);
    event TransferFailed(address indexed user, address indexed recipient, uint256 amount, string reason);

    
    bytes32 private constant METATRANSACTION_TYPEHASH = keccak256(
        "MetaTransaction(address user,address recipient,uint256 amount,uint256 nonce)"
    );

    constructor() EIP712("GasRelayerSystem", "1") {}

    
    function deposit() external payable {
        require(msg.value > 0, "Must deposit more than 0");
        balances[msg.sender] += msg.value;
    }

    
    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount; 

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Withdraw failed");
    }

    
    function executeBatch(
        address[] calldata users,
        address[] calldata recipients,
        uint256[] calldata amounts,
        bytes[] calldata signatures
    ) external {
        require(users.length == recipients.length && users.length == amounts.length && users.length==signatures.length, "Array mismatch");

        for (uint256 i = 0; i < users.length; i++) {
            _verifyAndExecute(users[i], recipients[i], amounts[i], signatures[i]);
        }
    }

    function _verifyAndExecute(
        address user,
        address recipient,
        uint256 amount,
        bytes memory signature
    ) internal {
        
        bytes32 structHash = keccak256(
            abi.encode(
                METATRANSACTION_TYPEHASH,
                user,
                recipient,
                amount,
                nonces[user]
            )
        );

        bytes32 hash = _hashTypedDataV4(structHash);

        
        address signer = hash.recover(signature);
        require(signer == user, "Invalid signature");

        
        require(balances[user] >= amount, "Insufficient user balance");

        
        nonces[user]++;
        balances[user] -= amount;

        
        (bool success, ) = recipient.call{value: amount}("");

        if (success) {
            
            emit TransferSuccess(user, recipient, amount);
        } else {
            
            balances[user] += amount;

            
            emit TransferFailed(user, recipient, amount, "ETH transfer rejected");
        }
    }

    
    receive() external payable {
        balances[msg.sender] += msg.value;
    }
}
