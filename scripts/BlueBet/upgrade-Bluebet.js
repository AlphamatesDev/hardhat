// scripts/upgrade-handsree.js
const { ethers, upgrades } = require("hardhat");

async function main() {
  const BlueBet = await ethers.getContractFactory("BlueBet");
  const bluebet = await upgrades.upgradeProxy('0x03272d7970e3D9bb023996530f465a152Beb39c7', BlueBet);
  console.log("BlueBet contract upgraded");
}

main();