import { ethers } from "ethers";

// Your contract address here
const contractAddress = " 0x24847F957737664beeAd64790A130aA2eC52E27F ";

// Contract ABI (copy-paste from compiled JSON or manually)
const contractABI = [
    // Simplified ABI
    "function deposit() external payable",
    "function withdrawToBeneficiary(uint256 amount) external",
    "function updateDailyLimitAndBeneficiary(uint256 newLimit, address newBeneficiary) external",
    "function updateDailyLimit(uint256 newLimit) external",
    "function emergencyPause() external",
    "function unpause() external",
    "function recoverETH(address payable to, uint256 amount) external",
    "function transferOwnership(address newOwner) external",
    "function getCurrentDay() external view returns (uint256)",
    "function getRemainingDailyLimit() external view returns (uint256)",
    "function dailyLimit() external view returns (uint256)",
    "function totalBalance() external view returns (uint256)",
    "function beneficiary() external view returns (address)",
    "function paused() external view returns (bool)",
    "function owner() external view returns (address)",
];

let provider;
let signer;
let contract;

async function connectWallet() {
    if (!window.ethereum) {
        alert("MetaMask not installed!");
        return;
    }
    provider = new ethers.providers.Web3Provider(window.ethereum);
    await provider.send("eth_requestAccounts", []);
    signer = provider.getSigner();
    contract = new ethers.Contract(contractAddress, contractABI, signer);
    await refreshUI();
}

async function refreshUI() {
    const balance = await contract.totalBalance();
    const limit = await contract.dailyLimit();
    const remaining = await contract.getRemainingDailyLimit();
    const currentBeneficiary = await contract.beneficiary();
    const paused = await contract.paused();

    document.getElementById("balance").innerText = ethers.utils.formatEther(balance) + " ETH";
    document.getElementById("dailyLimit").innerText = ethers.utils.formatEther(limit) + " ETH";
    document.getElementById("remainingLimit").innerText = ethers.utils.formatEther(remaining) + " ETH";
    document.getElementById("beneficiary").innerText = currentBeneficiary;
    document.getElementById("pausedStatus").innerText = paused ? "Paused" : "Active";
}

async function deposit() {
    const amount = document.getElementById("depositAmount").value;
    const tx = await contract.deposit({ value: ethers.utils.parseEther(amount) });
    await tx.wait();
    await refreshUI();
}

async function withdraw() {
    const amount = document.getElementById("withdrawAmount").value;
    const tx = await contract.withdrawToBeneficiary(ethers.utils.parseEther(amount));
    await tx.wait();
    await refreshUI();
}

async function updateLimitAndBeneficiary() {
    const newLimit = document.getElementById("newLimit").value;
    const newBeneficiary = document.getElementById("newBeneficiary").value;
    const tx = await contract.updateDailyLimitAndBeneficiary(
        ethers.utils.parseEther(newLimit),
        newBeneficiary
    );
    await tx.wait();
    await refreshUI();
}

async function pauseContract() {
    const tx = await contract.emergencyPause();
    await tx.wait();
    await refreshUI();
}

async function unpauseContract() {
    const tx = await contract.unpause();
    await tx.wait();
    await refreshUI();
}

async function recoverFunds() {
    const to = document.getElementById("recoverAddress").value;
    const amount = document.getElementById("recoverAmount").value;
    const tx = await contract.recoverETH(to, ethers.utils.parseEther(amount));
    await tx.wait();
    await refreshUI();
}

async function transferOwnership() {
    const newOwner = document.getElementById("newOwnerAddress").value;
    const tx = await contract.transferOwnership(newOwner);
    await tx.wait();
    await refreshUI();
}

window.connectWallet = connectWallet;
window.deposit = deposit;
window.withdraw = withdraw;
window.updateLimitAndBeneficiary = updateLimitAndBeneficiary;
window.pauseContract = pauseContract;
window.unpauseContract = unpauseContract;
window.recoverFunds = recoverFunds;
window.transferOwnership = transferOwnership;
