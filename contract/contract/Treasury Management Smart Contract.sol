// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TreasuryManagement {
    address public owner;
    uint256 public totalBalance;
    uint256 public totalDeposits;

    event Deposited(address indexed from, uint256 amount);
    event Withdrawn(address indexed to, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
        totalDeposits += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    // Function to withdraw funds from the treasury
    function withdraw(address payable recipient, uint256 amount) external onlyOwner {
        require(amount <= totalBalance, "Insufficient funds");
        totalBalance -= amount;
        recipient.transfer(amount);
        emit Withdrawn(recipient, amount);
    }

    // Function to check the treasury balance (in ETH)
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // Function to transfer ownership
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    // Function for emergency withdrawal of all funds
    function emergencyWithdraw() external onlyOwner {
        uint256 amount = address(this).balance;
        totalBalance = 0;
        payable(owner).transfer(amount);
        emit Withdrawn(owner, amount);
    }

    // Function to view total deposits (lifetime)
    function getTotalDeposits() external view returns (uint256) {
        return totalDeposits;
    }
}
