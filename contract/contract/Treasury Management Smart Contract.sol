// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TreasuryManagement {
    address public owner;
    uint256 public totalBalance;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }
    // Function to deposit ETH to the treasury
    receive() external payable {
        totalBalance += msg.value;
    }
    // Function to withdraw funds from the treasury
    function withdraw(address payable recipient, uint256 amount) external onlyOwner {
        require(amount <= totalBalance, "Insufficient funds");
        totalBalance -= amount;
        recipient.transfer(amount);
    }
    // Function to check the treasury balance (in ETH)
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}

