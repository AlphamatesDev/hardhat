const { utils } = require("ethers");
const crypto = require( 'crypto' );

async function main() {
    const StakingContract = await ethers.getContractFactory("StakingContract");
    const stakingContract = await StakingContract.deploy();
    await stakingContract.deployed();
    console.log("StakingContract address: ", stakingContract.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });