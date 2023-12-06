const { utils } = require("ethers");
const crypto = require( 'crypto' );

async function main() {
    const StakingPPC = await ethers.getContractFactory("StakingPPC");
    const stakingPPC = await StakingPPC.deploy();
    await stakingPPC.deployed();
    console.log("StakingPPC address: ", stakingPPC.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });