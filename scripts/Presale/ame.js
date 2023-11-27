const { utils } = require("ethers");
const randomwords = require( "random-words" ); //randomwords and crypto are to avoid userid collision
const crypto = require( 'crypto' );

async function main() {
    let metaarabs;
    let owner, accounts;

    [owner, ...accounts] = await ethers.getSigners();

    const ScaPassContract = await ethers.getContractFactory("FBX");
    const scapass = await ScaPassContract.deploy("FBX", "FBX", 500_000_000);
    await scapass.deployed();
    console.log("ScaPassContract address: ", scapass.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });