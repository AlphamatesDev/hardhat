// scripts/create-handsree.js
const { ethers, upgrades } = require("hardhat");

async function getLatestNonce() {
  const provider = ethers.provider;
  const latestNonce = await provider.getTransactionCount("0x792fA42DC844AC111843857614474c8df5b225c5");
  console.log("Latest Nonce:", latestNonce);
}

async function main() {
  
  // await getLatestNonce();
  // return;

  const PulsePixelCartel = await ethers.getContractFactory("PulsePixelCartel");
  const pulsepixelcartel = await upgrades.deployProxy(PulsePixelCartel, [], { initializer: 'initialize' });
  await pulsepixelcartel.deployed();
  console.log("PulsePixelCartel deployed to:", pulsepixelcartel.address);
}

main();