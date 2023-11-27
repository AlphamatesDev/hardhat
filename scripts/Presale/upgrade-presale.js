// scripts/upgrade-handsree.js
const { ethers, upgrades } = require("hardhat");

async function main() {
  const Presale = await ethers.getContractFactory("BluIDO");
  const presale = await upgrades.upgradeProxy('0x6B9B23D0E2113B44CE87d40132ac4d458500c33a', Presale);
  console.log("Presale contract upgraded");
}

main();