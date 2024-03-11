const { utils } = require("ethers");
const crypto = require( 'crypto' );

async function main() {
    // const StakingRaijins = await ethers.getContractFactory("StakingRaijins");
    // const stakingRaijins = await StakingRaijins.deploy();
    // await stakingRaijins.deployed();
    // console.log("StakingRaijins address: ", stakingRaijins.address);

    const StakingRaijins = await ethers.getContractFactory("StakingRaijinsMatic");
    const stakingRaijins = await StakingRaijins.deploy();
    await stakingRaijins.deployed();
    console.log("StakingRaijins address: ", stakingRaijins.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });