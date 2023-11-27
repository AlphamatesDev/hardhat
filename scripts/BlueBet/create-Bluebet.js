// scripts/create-handsree.js
const { ethers, upgrades } = require("hardhat");

async function main() {
  ////////////////////////////////////////////////////
  // const [deployer] = await ethers.getSigners();

  // console.log('Deploying ProxyAdmin contract with the account:', deployer.address);

  // const proxyAdmin = await upgrades.deployProxyAdmin();
  // await proxyAdmin.deployed();

  // console.log('ProxyAdmin deployed to:', proxyAdmin.address);

///////////////////////////////////////////////////////////////
  const BlueBet = await ethers.getContractFactory("BlueBet");
  
  const bluebet = await upgrades.deployProxy(BlueBet, [], { initializer: 'initialize' });
  await bluebet.deployed();
  console.log("BlueBetFactory deployed to:", bluebet.address);
}

main();