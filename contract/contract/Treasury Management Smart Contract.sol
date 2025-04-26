// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

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
    event DepositedWithMessage(address indexed from, uint256 amount, string message);
    event Withdrawn(address indexed to, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Paused();
    event Unpaused();
    event DailyLimitUpdated(uint256 newLimit);
    event BeneficiaryChanged(address indexed oldBeneficiary, address indexed newBeneficiary);
    event TokensRecovered(address token, address to, uint256 amount);

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

    receive() external payable {
        totalBalance += msg.value;
        totalDeposits += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    fallback() external payable {
        totalBalance += msg.value;
        totalDeposits += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function depositWithMessage(string calldata message) external payable whenNotPaused {
        totalBalance += msg.value;
        totalDeposits += msg.value;
        emit DepositedWithMessage(msg.sender, msg.value, message);
    }

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

    function multiWithdraw(address payable[] calldata recipients, uint256[] calldata amounts) external onlyOwner whenNotPaused {
        require(recipients.length == amounts.length, "Mismatched arrays");

        uint256 totalAmount;
        uint256 currentDay = block.timestamp / 1 days;
        if (currentDay > lastWithdrawalDay) {
            dailyWithdrawn = 0;
            lastWithdrawalDay = currentDay;
        }

        for (uint256 i = 0; i < recipients.length; i++) {
            totalAmount += amounts[i];
        }

        require(totalAmount <= totalBalance, "Insufficient funds");
        require(dailyWithdrawn + totalAmount <= dailyLimit, "Exceeds daily limit");

        totalBalance -= totalAmount;
        dailyWithdrawn += totalAmount;

        for (uint256 i = 0; i < recipients.length; i++) {
            recipients[i].transfer(amounts[i]);
            emit Withdrawn(recipients[i], amounts[i]);
        }
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

    function updateOwnerAndBeneficiary(address newOwner, address newBeneficiary) external onlyOwner {
        require(newOwner != address(0) && newBeneficiary != address(0), "Invalid addresses");
        emit OwnershipTransferred(owner, newOwner);
        emit BeneficiaryChanged(beneficiary, newBeneficiary);
        owner = newOwner;
        beneficiary = newBeneficiary;
    }

    function pause() external onlyOwner {
        paused = true;
        emit Paused();
    }

    function unpause() external onlyOwner {
        paused = false;
        emit Unpaused();
    }

    function setDailyLimit(uint256 limit) external onlyOwner {
        dailyLimit = limit;
        emit DailyLimitUpdated(limit);
    }

    function setBeneficiary(address newBeneficiary) external onlyOwner {
        require(newBeneficiary != address(0), "Invalid address");
        emit BeneficiaryChanged(beneficiary, newBeneficiary);
        beneficiary = newBeneficiary;
    }

    function recoverERC20(address tokenAddress, address to, uint256 amount) external onlyOwner {
        require(tokenAddress != address(0) && to != address(0), "Invalid address");
        IERC20(tokenAddress).transfer(to, amount);
        emit TokensRecovered(tokenAddress, to, amount);
    }
}
