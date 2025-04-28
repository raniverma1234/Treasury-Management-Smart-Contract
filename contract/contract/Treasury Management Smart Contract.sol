// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TreasuryManager {
    address public owner;
    address public beneficiary;
    uint256 public dailyLimit;
    uint256 public dailyWithdrawn;
    uint256 public lastWithdrawalDay;
    uint256 public totalBalance;
    bool public paused;

    event DailyLimitUpdated(uint256 newLimit);
    event BeneficiaryChanged(address indexed oldBeneficiary, address indexed newBeneficiary);
    event Withdrawn(address indexed to, uint256 amount);
    event Paused();
    event Unpaused();
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);
    event Deposited(address indexed from, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Paused");
        _;
    }

    constructor(address _beneficiary, uint256 _dailyLimit) {
        require(_beneficiary != address(0), "Invalid beneficiary address");
        owner = msg.sender;
        beneficiary = _beneficiary;
        dailyLimit = _dailyLimit;
    }

    receive() external payable {
        totalBalance += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function deposit() external payable {
        totalBalance += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function updateDailyLimitAndBeneficiary(uint256 newLimit, address newBeneficiary) external onlyOwner {
        require(newBeneficiary != address(0), "Invalid address");
        dailyLimit = newLimit;
        emit DailyLimitUpdated(newLimit);

        emit BeneficiaryChanged(beneficiary, newBeneficiary);
        beneficiary = newBeneficiary;
    }

    function updateDailyLimit(uint256 newLimit) external onlyOwner {
        dailyLimit = newLimit;
        emit DailyLimitUpdated(newLimit);
    }

    function withdrawToBeneficiary(uint256 amount) external onlyOwner whenNotPaused {
        require(amount <= totalBalance, "Insufficient funds");

        uint256 currentDay = block.timestamp / 1 days;
        if (currentDay > lastWithdrawalDay) {
            dailyWithdrawn = 0;
            lastWithdrawalDay = currentDay;
        }

        require(dailyWithdrawn + amount <= dailyLimit, "Exceeds daily limit");

        totalBalance -= amount;
        dailyWithdrawn += amount;
        payable(beneficiary).transfer(amount);
        emit Withdrawn(beneficiary, amount);
    }

    function emergencyPause() external onlyOwner {
        paused = true;
        emit Paused();

        uint256 amount = address(this).balance;
        if (amount > 0) {
            totalBalance = 0;
            payable(owner).transfer(amount);
            emit Withdrawn(owner, amount);
        }
    }

    function unpause() external onlyOwner {
        paused = false;
        emit Unpaused();
    }

    function recoverETH(address payable to, uint256 amount) external onlyOwner {
        require(to != address(0), "Invalid address");
        require(amount <= address(this).balance, "Insufficient ETH balance");
        totalBalance -= amount;
        to.transfer(amount);
        emit Withdrawn(to, amount);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid owner address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    // View functions
    function getCurrentDay() external view returns (uint256) {
        return block.timestamp / 1 days;
    }

    function getRemainingDailyLimit() external view returns (uint256) {
        uint256 currentDay = block.timestamp / 1 days;
        if (currentDay > lastWithdrawalDay) {
            return dailyLimit;
        } else {
            return dailyLimit - dailyWithdrawn;
        }
    }
}
