const { utils } = require("ethers");
const crypto = require( 'crypto' );

async function main() {
    let metaarabs;
    let owner, accounts;

    [owner, ...accounts] = await ethers.getSigners();

    const OverToken = await ethers.getContractFactory("OVERSWAP");

    console.log("mylog1");
    overtoken = await OverToken.deploy();
    console.log("mylog2");
    await overtoken.deployed();
    console.log("overtoken address: ", overtoken.address);

    // await overtoken.unPause();
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });