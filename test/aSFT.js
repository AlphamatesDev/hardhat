const { expect } = require("chai");

describe("Staking contract", function () {
  it("Deployment should assign the total supply of tokens to the owner", async function () {
    
    const [owner, addr1, addr2] = await ethers.getSigners();

    const Staking = await ethers.getContractFactory("Staking");
    const Reward = await ethers.getContractFactory("SmartFinanceToken");

    const htASFTToken = await Reward.deploy();
    console.log("Owner aSFT Total Supply: ", await htASFTToken.balanceOf(owner.address));

    await htASFTToken.transfer(addr1.address, 100 * 1000000000000000000);
    console.log("owner aSFT Balance: ", await htASFTToken.balanceOf(owner.address));

    console.log("addr1 aSFT Balance: ", await htASFTToken.balanceOf(addr1.address));

    // const htStaking = await Staking.deploy();
    // await htStaking.add(30, 30);
    // await htStaking.add(60, 40);
    // await htStaking.add(90, 50);
    // await htStaking.add(180, 60);
    // await htStaking.add(360, 80);

    // const nCnt = await htStaking.poolLength();
    // console.log("poolLength: ", nCnt);


    // await htStaking.initialize(htASFTToken.address, htASFTToken.address, 0, 10000000000000);
    // console.log("rewardToken: ", await htStaking.rewardToken());

    // await htASFTToken.connect(addr1).approve(htStaking.address, 100 );
    //await htStaking.connect(addr1).deposit(0, 10);


    //const ownerBalance = await htToken.balanceOf(owner.address);
    //expect(await htToken.totalSupply()).to.equal(ownerBalance);
  });
});