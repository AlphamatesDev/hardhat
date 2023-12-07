const { utils } = require("ethers");
const crypto = require( 'crypto' );

async function main() {
    const RaffleLOH = await ethers.getContractFactory("RaffleLOH");
    const raffleLOH = await RaffleLOH.deploy();
    await raffleLOH.deployed();
    console.log("RaffleLOH address: ", raffleLOH.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });