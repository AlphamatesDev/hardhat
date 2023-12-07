// scripts/create-handsree.js
const { ethers, upgrades } = require("hardhat");

async function main() {
  const LOHTicketRouter = await ethers.getContractFactory("LOHTicketRouter");
  
  const lohTicketRouter = await upgrades.deployProxy(LOHTicketRouter, [], { initializer: 'initialize' });
  await lohTicketRouter.deployed();
  console.log("LOHTicketRouter deployed to:", lohTicketRouter.address);
}

main();