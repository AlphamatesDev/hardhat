const { utils } = require("ethers");
const crypto = require( 'crypto' );

async function main() {
    const LUCIA = await ethers.getContractFactory("LUCIA");
    const lucia = await LUCIA.deploy();
    await lucia.deployed();
    console.log("LUCIA address: ", lucia.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });