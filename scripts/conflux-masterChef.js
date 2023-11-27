const { utils } = require("ethers");
const crypto = require( 'crypto' );

async function main() {
    let metaarabs;
    let owner, accounts;

    [owner, ...accounts] = await ethers.getSigners();

    const OverToken = await ethers.getContractFactory("MasterChef");

    console.log("mylog1");
    overtoken = await OverToken.deploy("0xe669E77B2A9311Efbea22Ae8E5f6824ae20941a7", 
        "0x16970d8Fb91d6B54b0b825DFB3B46908a12602d3", 
        1000000000000000, 
        1000000000000000);
    console.log("mylog2");
    await overtoken.deployed();
    console.log("MasterChef contract address: ", overtoken.address);

    // await overtoken.unPause();
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });