const { utils } = require("ethers");
const crypto = require( 'crypto' );

async function main() {
    const StakingLOH = await ethers.getContractFactory("StakingLOH");
    const stakingLOH = await StakingLOH.deploy();
    await stakingLOH.deployed();
    console.log("StakingLOH address: ", stakingLOH.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });