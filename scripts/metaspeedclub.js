const { utils } = require("ethers");
const randomwords = require( "random-words" ); //randomwords and crypto are to avoid userid collision
const crypto = require( 'crypto' );

async function main() {
    let metaarabs;
    let owner, accounts;

    [owner, ...accounts] = await ethers.getSigners();

    // const MetaSpeedClub = await ethers.getContractFactory("MetaSpeedClub");
    // metaSpeedClub = await MetaSpeedClub.deploy();
    // await metaSpeedClub.deployed();
    // console.log("metaSpeedClub address: ", metaSpeedClub.address);

    const RewardToken = await ethers.getContractFactory("RewardToken");
    rewardToken = await RewardToken.deploy();
    await rewardToken.deployed();
    console.log("rewardToken address: ", rewardToken.address);

    // const StakingContract = await ethers.getContractFactory("StakingContract");
    // stakingContract = await StakingContract.deploy(rewardToken.address, metaSpeedClub.address);
    // await stakingContract.deployed();
    // console.log("stakingContract address: ", stakingContract.address);

    // await metaSpeedClub.unPause();
    // await rewardToken.transfer(stakingContract.address, ethers.utils.parseEther("100000"))
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });