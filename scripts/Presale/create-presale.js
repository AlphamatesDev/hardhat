// scripts/create-handsree.js
const { ethers, upgrades } = require("hardhat");

async function main() {
  const Presale = await ethers.getContractFactory("BluIDO");
  
  const presale = await upgrades.deployProxy(Presale, [], { initializer: 'initialize' });
  await presale.deployed();
  console.log("PresaleFactory deployed to:", presale.address);
}

main();