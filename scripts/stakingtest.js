const { utils } = require("ethers");
const randomwords = require( "random-words" ); //randomwords and crypto are to avoid userid collision
const crypto = require( 'crypto' );

async function main() {
    let metaarabs;
    let owner, accounts;

    [owner, ...accounts] = await ethers.getSigners();

    const Staking = await ethers.getContractFactory("Staking");

    console.log("mylog1");
    stakingtest = await Staking.deploy();
    console.log("mylog2");
    await stakingtest.deployed();
    console.log("stakingtest address: ", stakingtest.address);

    // await stakingtest.unPause();
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });