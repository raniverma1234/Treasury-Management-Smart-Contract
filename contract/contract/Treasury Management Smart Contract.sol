  function updateDailyLimitAndBeneficiary(uint256 newLimit, address newBeneficiary) external onlyOwner {
        require(newBeneficiary != address(0), "Invalid address");
        dailyLimit = newLimit;
        emit DailyLimitUpdated(newLimit);

        emit BeneficiaryChanged(beneficiary, newBeneficiary);
        beneficiary = newBeneficiary;
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

    function recoverETH(address payable to, uint256 amount) external onlyOwner {
        require(to != address(0), "Invalid address");
        require(amount <= address(this).balance, "Insufficient ETH balance");
        totalBalance -= amount;
        to.transfer(amount);
        emit Withdrawn(to, amount);
    }
