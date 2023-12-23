const { utils } = require("ethers");
const crypto = require( 'crypto' );

async function main() {
    const LOHTicketRouter = await ethers.getContractFactory("LOHTicketRouter");
    const lohTicketRouter = await LOHTicketRouter.deploy();
    await lohTicketRouter.deployed();
    console.log("LOHTicketRouter address: ", lohTicketRouter.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });