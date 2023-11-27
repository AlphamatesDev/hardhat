const { utils } = require("ethers");
const randomwords = require( "random-words" ); //randomwords and crypto are to avoid userid collision
const crypto = require( 'crypto' );

async function main() {
    let metaarabs;
    let owner, accounts;

    [owner, ...accounts] = await ethers.getSigners();

    // const Lib = await ethers.getContractFactory("Calculations");
    // const lib = await Lib.deploy();
    // await lib.deployed();
    // const lib = await contractAt("Calculations", "0xad88AA66885b4a04025C0a84e5fee5c301E05D2d");
    // console.log("Calculations contract address: ", lib.address);

    const VICoin = await ethers.getContractFactory("VICoin");
    viCoin = await VICoin.deploy("VI Berlin", // name
      "VALUE", // symbol
      43200, // lifetime
      ethers.BigNumber.from(16).mul(ethers.BigNumber.from(10).pow(18)), // _generationAmount
      240, // _generationPeriod
      2 * (10**2), // _communityContribution
      33.33 * (10**2), // _transactionFee
      ethers.BigNumber.from(200).mul(ethers.BigNumber.from(10).pow(18)), // _initialBalance
      "0xC8053062D7385941a693100bbe5c0B0c73267Aaf", // _communityContributionAccount
      "0xC8053062D7385941a693100bbe5c0B0c73267Aaf");
    await viCoin.deployed();
    console.log("VICoin contract address: ", viCoin.address);

  //   await sendTxn(VICoin.initialize(
  //   "VI Berlin", // name
  //   "VALUE", // symbol
  //   18, // decimal
  //   16 * (10**18), // _generationAmount
  //   240, // _generationPeriod
  //   2 * (10**2), // _communityContribution
  //   33.33 * (10**2), // _transactionFee
  //   200 * (10**18), // _initialBalance
  //   "0xC8053062D7385941a693100bbe5c0B0c73267Aaf", // _communityContributionAccount
  //   "0xC8053062D7385941a693100bbe5c0B0c73267Aaf" // _controller
  // ), "VICoin.initialize");
    // await viCoin.unPause();
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });