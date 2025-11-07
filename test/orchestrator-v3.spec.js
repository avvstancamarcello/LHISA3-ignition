const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");

describe("OceanMangaOrchestratorV3", function () {
    let owner, user, creator, charityFund, otherUser;
    let orchestrator;
    let mockNFT, mockFT;
    const FT_SHARE = 950; // 95% (residuo che rimane nel contratto)

    beforeEach(async function () {
        [owner, user, creator, charityFund, otherUser] = await ethers.getSigners();

        // Deploy Mock CosmixSolidaryToken (FT)
        const MockFTFactory = await ethers.getContractFactory("CosmixSolidaryToken");
        mockFT = await upgrades.deployProxy(MockFTFactory, [owner.address, ethers.parseEther("1000000"), owner.address], { initializer: 'initialize' });
        await mockFT.waitForDeployment();

        // Deploy Mock OceanMangaNFT
        // This mock is now upgradeable to be consistent with the project's structure
    const MockNFTFactory = await ethers.getContractFactory("contracts/mocks/OceanMangaNFT_Simple.sol:OceanMangaNFT_Simple");
        mockNFT = await upgrades.deployProxy(MockNFTFactory, [owner.address], { initializer: 'initialize' });
        await mockNFT.waitForDeployment();

        // Deploy OceanMangaOrchestratorV3
        const OrchestratorFactory = await ethers.getContractFactory("OceanMangaOrchestratorV3");
        orchestrator = await upgrades.deployProxy(OrchestratorFactory, [
            mockNFT.target,
            mockFT.target,
            creator.address,
            charityFund.address
        ], { initializer: 'initialize' });
        await orchestrator.waitForDeployment();

    // Grant roles to the orchestrator (explicitly)
    const MINTER_ROLE_FT = await mockFT.MINTER_ROLE();
    const MINTER_ROLE_NFT = await mockNFT.MINTER_ROLE();
    // Grant FT minter role
    await mockFT.connect(owner).grantRole(MINTER_ROLE_FT, orchestrator.target);
    // Grant NFT minter role
    await mockNFT.connect(owner).grantRole(MINTER_ROLE_NFT, orchestrator.target);
    });

    describe("Deployment", function () {
        it("Should set the correct addresses and initial values", async function () {
            expect(await orchestrator.oceanMangaNFT()).to.equal(mockNFT.target);
            expect(await orchestrator.cosmixFT()).to.equal(mockFT.target);
            expect(await orchestrator.creator()).to.equal(creator.address);
            expect(await orchestrator.charityFund()).to.equal(charityFund.address);
            expect(await orchestrator.lockPeriod()).to.equal(90 * 24 * 60 * 60); // 90 days in seconds
        });
    });

    describe("Capital Guarantee Mechanism (30-Day Lock)", function () {
        it("Should lock user's funds in the contract upon minting", async function () {
            const mintPrice = ethers.parseEther("1.0");

            // Check initial balance of the orchestrator
            const initialOrchestratorBalance = await ethers.provider.getBalance(orchestrator.target);
            expect(initialOrchestratorBalance).to.equal(0);

            // User mints a photo combo
            await orchestrator.connect(user).mintPhotoCombo("some-token-uri", { value: mintPrice });

            // Calcola la quota residua che rimane nel contratto
            // FT_SHARE = 45%, quindi rimane 0.95 ETH (1000 - 25 - 25 = 950)
            const expectedResidue = mintPrice * BigInt(FT_SHARE) / BigInt(1000);
            const finalOrchestratorBalance = await ethers.provider.getBalance(orchestrator.target);
            expect(finalOrchestratorBalance).to.equal(expectedResidue);

            // Verifica che creator e charity abbiano ricevuto la loro quota
            // (opzionale: si può aggiungere un controllo sui balance, ma la logica del contratto è ora rispettata)
        });

        it("Should distribute only creator and charity shares after lock, and allow residue withdrawal", async function () {
            const mintPrice = ethers.parseEther("1.0");

            // User mints a photo combo
            const tx = await orchestrator.connect(user).mintPhotoCombo("some-token-uri", { value: mintPrice });
            const receipt = await tx.wait();
            // Estrai il tokenId dall'evento PhotoMinted
            const event = receipt.logs.find(l => l.fragment && l.fragment.name === "PhotoMinted");
            const tokenId = event ? event.args.nftId : 1;

            // Avanza il tempo oltre il lock
            await time.increase(91 * 24 * 60 * 60); // 91 giorni

            // Saldi prima della distribuzione
            const creatorBalanceBefore = await ethers.provider.getBalance(creator.address);
            const charityBalanceBefore = await ethers.provider.getBalance(charityFund.address);
            const contractBalanceBefore = await ethers.provider.getBalance(orchestrator.target);

            // Distribuisci post-lock
            await orchestrator.distributePostLock(tokenId);

            // Saldi dopo la distribuzione
            const creatorBalanceAfter = await ethers.provider.getBalance(creator.address);
            const charityBalanceAfter = await ethers.provider.getBalance(charityFund.address);
            const contractBalanceAfter = await ethers.provider.getBalance(orchestrator.target);

            // Calcola le quote distribuite
            const expectedCreator = contractBalanceBefore * BigInt(25) / BigInt(1000);
            const expectedCharity = contractBalanceBefore * BigInt(25) / BigInt(1000);
            const expectedResidue = contractBalanceBefore - expectedCreator - expectedCharity;

            expect(creatorBalanceAfter - creatorBalanceBefore).to.equal(expectedCreator);
            expect(charityBalanceAfter - charityBalanceBefore).to.equal(expectedCharity);
            expect(contractBalanceAfter).to.equal(expectedResidue);

            // Ora il wallet proprietario può ritirare il residuo
            const ownerBalanceBefore = await ethers.provider.getBalance(owner.address);
            const txWithdraw = await orchestrator.connect(owner).withdrawResidue(owner.address);
            const receiptWithdraw = await txWithdraw.wait();
            const ownerBalanceAfter = await ethers.provider.getBalance(owner.address);
            // Il residuo deve essere stato trasferito, con una tolleranza del 10% per i guadagni di staking
            const stakingTolerance = 0.10; // 10%
            const minResidue = expectedResidue - (expectedResidue * BigInt(Math.floor(stakingTolerance * 100)) / BigInt(100));
            const maxResidue = expectedResidue + (expectedResidue * BigInt(Math.floor(stakingTolerance * 100)) / BigInt(100));
            expect(ownerBalanceAfter - ownerBalanceBefore).to.be.within(minResidue, maxResidue);
            const contractBalanceFinal = await ethers.provider.getBalance(orchestrator.target);
            expect(contractBalanceFinal).to.equal(0);
        });

        // More tests for refund, distribution after 30 days, etc. will be added here.
    });
});
