const { utils } = require("ethers");
const randomwords = require( "random-words" ); //randomwords and crypto are to avoid userid collision
const crypto = require( 'crypto' );

async function main() {
    let metaarabs;
    let owner, accounts;

    [owner, ...accounts] = await ethers.getSigners();

    const Metaarabs = await ethers.getContractFactory("Metaarabs");
    metaarabs = await Metaarabs.deploy();
    await metaarabs.deployed();
    console.log("metaarabs address: ", metaarabs.address);

    await metaarabs.unPause();    
    await metaarabs.mintNFTForOwner();
    console.log("Owner Balance: ", await metaarabs.balanceOf(owner.address));
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });