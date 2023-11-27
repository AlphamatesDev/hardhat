const { utils } = require("ethers");
const randomwords = require( "random-words" ); //randomwords and crypto are to avoid userid collision
const crypto = require( 'crypto' );

async function main() {
    let metaarabs;
    let owner, accounts;

    [owner, ...accounts] = await ethers.getSigners();

    const SwapContract = await ethers.getContractFactory("SwapContract");
    swapContract = await SwapContract.deploy("0x86557C01B77C0e65c8aB87fbA6D221E94EdC81e4");
    await swapContract.deployed();
    console.log("swapContract address: ", swapContract.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });