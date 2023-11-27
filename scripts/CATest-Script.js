const { utils } = require("ethers");
const randomwords = require( "random-words" ); //randomwords and crypto are to avoid userid collision
const crypto = require( 'crypto' );

async function main() {
    let metaarabs;
    let owner, accounts;

    [owner, ...accounts] = await ethers.getSigners();

    // const BToken = await ethers.getContractFactory("BToken");
    // bToken = await BToken.deploy();
    // await bToken.deployed();
    // console.log("BToken address: ", bToken.address);

    // const Multicall2 = await ethers.getContractFactory("Multicall2");
    // multicall2 = await Multicall2.deploy();
    // await multicall2.deployed();
    // console.log("Multicall2 address: ", multicall2.address);

    const Escrow = await ethers.getContractFactory("Escrow");
    escrow = await Escrow.deploy(0);
    await escrow.deployed();
    console.log("Escrow address: ", escrow.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });