// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TreasuryManagement {
    address public owner;
    address public beneficiary;
    uint256 public totalBalance;
    uint256 public totalDeposits;
    bool public paused;

    uint256 public dailyLimit;
    uint256 public dailyWithdrawn;
    uint256 public lastWithdrawalDay;

    event Deposited(address indexed from, uint256 amount);
    event Withdrawn(address indexed to, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Paused();
    event Unpaused();
    event DailyLimitUpdated(uint256 newLimit);
    event BeneficiaryChanged(address indexed oldBeneficiary, address indexed newBeneficiary);

    constructor() {
        owner = msg.sender;
        beneficiary = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    // Receive function
    receive() external payable {
        totalBalance += msg.value;
        totalDeposits += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    // Fallback function
    fallback() external payable {
        totalBalance += msg.value;
        totalDeposits += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    // Withdraw with daily limit and pause check
    function withdraw(address payable recipient, uint256 amount) external onlyOwner whenNotPaused {
        require(amount <= totalBalance, "Insufficient funds");

        uint256 currentDay = block.timestamp / 1 days;
        if (currentDay > lastWithdrawalDay) {
            dailyWithdrawn = 0;
            lastWithdrawalDay = currentDay;
        }

        require(dailyWithdrawn + amount <= dailyLimit, "Exceeds daily limit");

        totalBalance -= amount;
        dailyWithdrawn += amount;
        recipient.transfer(amount);
        emit Withdrawn(recipient, amount);
    }

    function emergencyWithdraw() external onlyOwner {
        uint256 amount = address(this).balance;
        totalBalance = 0;
        payable(owner).transfer(amount);
        emit Withdrawn(owner, amount);
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getTotalDeposits() external view returns (uint256) {
        return totalDeposits;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    // Pause the contract
    function pause() external onlyOwner {
        paused = true;
        emit Paused();
    }

    // Unpause the contract
    function unpause() external onlyOwner {
        paused = false;
        emit Unpaused();
    }

    // Set a daily withdrawal limit (in wei)
    function setDailyLimit(uint256 limit) external onlyOwner {
        dailyLimit = limit;
        emit DailyLimitUpdated(limit);
    }

    // Set a new beneficiary (recipient of special payments if needed)
    function setBeneficiary(address newBeneficiary) external onlyOwner {
        require(newBeneficiary != address(0), "Invalid address");
        emit BeneficiaryChanged(beneficiary, newBeneficiary);
        beneficiary = newBeneficiary;
    }
}

