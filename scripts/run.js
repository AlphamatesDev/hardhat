const { utils } = require("ethers");
const randomwords = require( "random-words" ); //randomwords and crypto are to avoid userid collision
const crypto = require( 'crypto' );

async function main() {
    let metaarabs;
    let owner, accounts;

    [owner, ...accounts] = await ethers.getSigners();

    const SandwichBot = await ethers.getContractFactory("multiTransfer");
    const sandwichBot = await SandwichBot.deploy();
    console.log("Prev sandwichBot.deployed()");
    await sandwichBot.deployed();
    console.log("sandwichBot address: ", sandwichBot.address);

    // const FccToken = await ethers.getContractFactory("FccToken");
    // fccToken = await FccToken.deploy();
    // await fccToken.deployed();
    // console.log("FccToken address: ", fccToken.address);

    // const FccNFTStaking = await ethers.getContractFactory("FccNFTStaking");
    // fccNFTStaking = await FccNFTStaking.deploy(fccToken.address, fccNFT.address);
    // await fccNFTStaking.deployed();
    // console.log("FccNFTStaking address: ", fccNFTStaking.address);

    //await fccNFT.unPause();
    // await fccToken.transfer(stakingContract.address, ethers.utils.parseEther("100000"))
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });