// scripts/upgrade-handsree.js
const { ethers, upgrades } = require("hardhat");

async function main() {
  const PulsePixelCartel = await ethers.getContractFactory("PulsePixelCartel");
  const pulsepixelcartel = await upgrades.upgradeProxy('0x277B401D32C12274eF3aB83eBb6Fdd8550460b89', PulsePixelCartel);
  console.log("PulsePixelCartel upgraded");
}

main();