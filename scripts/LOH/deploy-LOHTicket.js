const { utils } = require("ethers");
const crypto = require( 'crypto' );

async function main() {
    const LOHTicket = await ethers.getContractFactory("LOHTicket");
    const lohTicket = await LOHTicket.deploy();
    await lohTicket.deployed();
    console.log("LOHTicket address: ", lohTicket.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });