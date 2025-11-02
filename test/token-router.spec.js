const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");

describe("SolidarySystemTokenRouter", function () {
    let TokenRouter;
    let tokenRouter;
    let owner;

    beforeEach(async function () {
        [owner] = await ethers.getSigners();

        // Deploy the contract
        TokenRouter = await ethers.getContractFactory("contracts/SolidarySystemTokenRouter.sol:SolidarySystemTokenRouter");
        tokenRouter = await upgrades.deployProxy(TokenRouter, [], { initializer: 'initialize' });
        await tokenRouter.waitForDeployment();
    });

    it("Should deploy correctly and have the correct constants", async function () {
        expect(await tokenRouter.FT_SHARE_BPS()).to.equal(4500);
        expect(await tokenRouter.NFT_SHARE_BPS()).to.equal(5500);
    });

    describe("calculateStellaDoppiaSplit", function () {
        it("Should correctly split a total value according to the 45/55 ratio", async function () {
            const totalValue = ethers.parseEther("100"); // 100 ETH
            const { ftValue, nftValue } = await tokenRouter.calculateStellaDoppiaSplit(totalValue);

            const expectedFtValue = (totalValue * 4500n) / 10000n;
            const expectedNftValue = (totalValue * 5500n) / 10000n;

            expect(ftValue).to.equal(expectedFtValue);
            expect(nftValue).to.equal(expectedNftValue);
            expect(ftValue + nftValue).to.equal(totalValue);
        });

        it("Should handle zero value correctly", async function () {
            const { ftValue, nftValue } = await tokenRouter.calculateStellaDoppiaSplit(0);
            expect(ftValue).to.equal(0);
            expect(nftValue).to.equal(0);
        });

        it("Should handle rounding correctly with small numbers", async function () {
            // With totalValue = 1, ftValue will be 0 and nftValue will be 0 due to integer division
            const { ftValue, nftValue } = await tokenRouter.calculateStellaDoppiaSplit(1);
            expect(ftValue).to.equal(0);
            expect(nftValue).to.equal(0);
        });
    });

    describe("calculateConversionValue", function () {
        it("Should calculate the correct conversion value for a 1:1 rate", async function () {
            const amount = ethers.parseEther("150"); // 150 tokens
            const rate = ethers.parseEther("1.0");   // Rate of 1:1
            
            const convertedValue = await tokenRouter.calculateConversionValue(amount, rate);
            expect(convertedValue).to.equal(amount);
        });

        it("Should calculate the correct conversion value for a 1:0.5 rate", async function () {
            const amount = ethers.parseEther("150"); // 150 tokens
            const rate = ethers.parseEther("0.5");   // Rate of 1:0.5
            
            const convertedValue = await tokenRouter.calculateConversionValue(amount, rate);
            expect(convertedValue).to.equal(ethers.parseEther("75"));
        });

        it("Should calculate the correct conversion value for a 1:2 rate", async function () {
            const amount = ethers.parseEther("150"); // 150 tokens
            const rate = ethers.parseEther("2.0");   // Rate of 1:2
            
            const convertedValue = await tokenRouter.calculateConversionValue(amount, rate);
            expect(convertedValue).to.equal(ethers.parseEther("300"));
        });

        it("Should handle zero amount correctly", async function () {
            const rate = ethers.parseEther("1.0");
            const convertedValue = await tokenRouter.calculateConversionValue(0, rate);
            expect(convertedValue).to.equal(0);
        });
    });
});
