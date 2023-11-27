const { utils } = require("ethers");
const randomwords = require( "random-words" ); //randomwords and crypto are to avoid userid collision
const crypto = require( 'crypto' );

async function main() {
    let metropyToken, genesis, vrfGenerator, obelisk, land, staking;
    let owner, accounts;

    [owner, ...accounts] = await ethers.getSigners();
    const MetropyToken = await ethers.getContractFactory("MetropyToken");
    metropyToken = await MetropyToken.deploy(1000000000);
    await metropyToken.deployed();
    console.log("MetropyToken address: ", metropyToken.address);

    const Genesis = await ethers.getContractFactory("Genesis");
    genesis = await Genesis.deploy();
    await genesis.deployed();
    console.log("Genesis address: ", genesis.address);

    const rand = process.env.PRIVATE_KEY;
    const VRFGenerator = await ethers.getContractFactory("VRFv2SubscriptionManager");
    vrfGenerator = await VRFGenerator.deploy(rand);
    await vrfGenerator.deployed();
    console.log("VRFGenerator address: ", vrfGenerator.address);

    const Obelisk = await ethers.getContractFactory("Obelisk");
    obelisk = await Obelisk.deploy("", metropyToken.address, vrfGenerator.address); // random function address
    await obelisk.deployed();
    console.log("Obelisk address: ", obelisk.address);

    const Land = await ethers.getContractFactory("Land");
    land = await Land.deploy("", metropyToken.address, obelisk.address, vrfGenerator.address);
    await land.deployed();
    console.log("Land address: ", land.address);

    const Staking = await ethers.getContractFactory("StakeToken");
    staking = await Staking.deploy(metropyToken.address, genesis.address, owner.address, land.address, obelisk.address);
    await staking.deployed();
    console.log("Staking address: ", staking.address);

    // preprocessing...........
    await genesis.pause(false);
    await obelisk.pause(false);
    await land.pause(false);
    await metropyToken.transfer(staking.address, ethers.utils.parseEther("1000000"));
    await obelisk.changeStakingAddress(staking.address);
    await land.changeStakingAddress(staking.address);

    await genesis.setPublicSale();
    await genesis.revealToken();
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });