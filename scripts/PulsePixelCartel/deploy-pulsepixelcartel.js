const { utils } = require("ethers");
const crypto = require( 'crypto' );

async function main() {
    const PulsePixelCartel = await ethers.getContractFactory("PulsePixelCartel");
    const pulsePixelCartel = await PulsePixelCartel.deploy();
    await pulsePixelCartel.deployed();
    console.log("PulsePixelCartel address: ", pulsePixelCartel.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });