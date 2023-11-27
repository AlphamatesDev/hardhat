const { expect } = require("chai");
const { ethers, network } = require("hardhat");
const { MerkleTree } = require('merkletreejs');
const keccak256 = require('keccak256');
require("@nomiclabs/hardhat-waffle");
// const { time } = require('openzeppelin-test-helpers');
const assert = require('assert').strict;
const provider = waffle.provider;

require("@nomiclabs/hardhat-ethers");

describe("Test Token", async function () {
    let owner, accounts;
    let testToken, fbxNFT
    before(async () => {
        [owner, ...accounts] = await ethers.getSigners();

        const TestToken = await ethers.getContractFactory("TestToken");
        testToken = await TestToken.deploy();
        await testToken.deployed();
        // console.log("mysticToken address: ", mysticToken.address);

        const FbxNFT = await ethers.getContractFactory("FbxNFT");
        fbxNFT = await FbxNFT.deploy("", testToken.address);
        await fbxNFT.deployed();
        // console.log("metaMysticSuperheroes address: ", metaMysticSuperheroes.address);
        
        // const FccNFT = await ethers.getContractFactory("FccNFT");
        // fccNFT = await FccNFT.deploy();
        // await fccNFT.deployed();
        // console.log("fccNFT address: ", fccNFT.address);
    });
    
    it("Can mint", async function () {
        let preSaleWhitelistAddresses = [  accounts[0].address, accounts[1].address, 
                                    accounts[2].address, accounts[3].address, 
                                    accounts[4].address];

        const preSaleLeafNodes = preSaleWhitelistAddresses.map(addr => keccak256(addr));
        const preSaleMerkleTree = new MerkleTree(preSaleLeafNodes, keccak256, {sortPairs: true});
        // const preSaleRootHash = preSaleMerkleTree.getRoot();

        let preSaleWhitelistAddresses1 = [  accounts[5].address, accounts[6].address, 
                                    accounts[7].address, accounts[8].address, 
                                    accounts[9].address];

        const preSaleLeafNodes1 = preSaleWhitelistAddresses1.map(addr => keccak256(addr));
        const preSaleMerkleTree1 = new MerkleTree(preSaleLeafNodes1, keccak256, {sortPairs: true});
        const preSaleRootHash = preSaleMerkleTree.getRoot();

        await fbxNFT.setMerkleRoot(preSaleMerkleTree.getHexRoot(), preSaleMerkleTree1.getHexRoot());

        let claimingAddress = keccak256(accounts[0].address);
        let hexProof = preSaleMerkleTree.getHexProof(claimingAddress);
        await fbxNFT.connect(accounts[0]).mint(1, 1, hexProof)
        console.log("Account 0 Balance: ", await fbxNFT.balanceOf(accounts[0].address, 1))
        
        await expect(fbxNFT.connect(accounts[0]).mint(1, 1, hexProof)).to.be.revertedWith("You can only mint 1 cards per wallet")
        await expect(fbxNFT.connect(accounts[0]).mint(1, 2, hexProof)).to.be.revertedWith("Address does not exist in whitelist.")
        await expect(fbxNFT.connect(accounts[10]).mint(1, 1, hexProof)).to.be.revertedWith("Address does not exist in whitelist.")
        
        let claimingAddress1 = keccak256(accounts[5].address);
        let hexProof1 = preSaleMerkleTree1.getHexProof(claimingAddress1);
        await fbxNFT.connect(accounts[5]).mint(1, 2, hexProof1)
        console.log("Account 5 Balance: ", await fbxNFT.balanceOf(accounts[5].address, 2))

        
        testToken.transfer(accounts[0].address, ethers.utils.parseEther("200"))
        console.log("Account 0 Token Balance:", ethers.utils.formatEther(await testToken.balanceOf(accounts[0].address)))
        testToken.connect(accounts[0]).approve(fbxNFT.address, ethers.utils.parseEther("200"))

        let claimingAddress3 = keccak256(accounts[0].address);
        let hexProof3 = preSaleMerkleTree.getHexProof(claimingAddress3);
        await fbxNFT.connect(accounts[0]).mint(1, 3, hexProof3)
        console.log("Account 0 Balance: ", await fbxNFT.balanceOf(accounts[0].address, 3))

        console.log("Account 0 Token Balance:", ethers.utils.formatEther(await testToken.balanceOf(accounts[0].address)))

        console.log("Owner 0 Token Balance:", ethers.utils.formatEther(await testToken.balanceOf(owner.address)))
        await fbxNFT.withdrawToken()
        console.log("Owner 0 Token Balance:", ethers.utils.formatEther(await testToken.balanceOf(owner.address)))
    });
});