const { utils } = require("ethers");
const crypto = require( 'crypto' );

async function main() {
    const BurningLOH = await ethers.getContractFactory("BurningLOH");
    const burningLOH = await BurningLOH.deploy();
    await burningLOH.deployed();
    console.log("BurningLOH address: ", burningLOH.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });