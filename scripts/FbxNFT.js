const { utils } = require("ethers");
// const randomwords = require( "random-words" ); //randomwords and crypto are to avoid userid collision
const crypto = require( 'crypto' );

async function main() {
    let metaarabs;
    let owner, accounts;

    [owner, ...accounts] = await ethers.getSigners();

    const ScaPassContract = await ethers.getContractFactory("AmeNFT");
    const scapass = await ScaPassContract.deploy("https://bullhead.mypinata.cloud/ipfs/Qmd1zs6QkBVKQzzpeFSoS7g9ZLUE338Dm1RTnYMszgMmeL/1", "0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56");
    await scapass.deployed();
    console.log("ScaPassContract address: ", scapass.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });