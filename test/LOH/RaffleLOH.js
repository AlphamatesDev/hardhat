const { expect } = require("chai");

describe("RaffleLOH contract", function () {
  it("Deployment should assign the total supply of tokens to the owner", async function () {
    const [owner] = await ethers.getSigners();

    const raffleLOH = await ethers.deployContract("RaffleLOH");

    // const ownerBalance = await hardhatToken.balanceOf(owner.address);
    // expect(await hardhatToken.totalSupply()).to.equal(ownerBalance);
  });
});