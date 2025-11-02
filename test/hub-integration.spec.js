const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");

describe("SolidarySystemHub Integration Test", function () {
    let hub;
    let owner, addr1;
    let orchestrator, ft, nft; // These will be mock addresses
    let tokenRouter;

    beforeEach(async function () {
        [owner, addr1] = await ethers.getSigners();

        // For testing the Hub in isolation, we don't need to deploy the actual dependencies.
        // We can use random addresses as placeholders.
        orchestrator = { target: ethers.Wallet.createRandom().address };
        ft = { target: ethers.Wallet.createRandom().address };
        nft = { target: ethers.Wallet.createRandom().address };
        
        // Deploy the Hub
        const HubFactory = await ethers.getContractFactory("SolidarySystemHub");
        hub = await upgrades.deployProxy(HubFactory, [], { initializer: 'initialize' });

        // Deploy the TokenRouter
        const TokenRouterFactory = await ethers.getContractFactory("contracts/SolidarySystemTokenRouter.sol:SolidarySystemTokenRouter");
        tokenRouter = await upgrades.deployProxy(TokenRouterFactory, [], { initializer: 'initialize' });

        await hub.waitForDeployment();
        await tokenRouter.waitForDeployment();
    });

    describe("Deployment and Initial State", function () {
        it("Should set the right owner", async function () {
            expect(await hub.owner()).to.equal(owner.address);
        });

        it("Should have no modules initially", async function () {
            const moduleIds = await hub.getModuleIds();
            expect(moduleIds.length).to.equal(0);
        });

        it("Should have no token router initially", async function () {
            expect(await hub.tokenRouter()).to.equal(ethers.ZeroAddress);
        });
    });

    describe("Token Router Management", function () {
        it("Should allow the owner to set the token router", async function () {
            await expect(hub.setTokenRouter(tokenRouter.target))
                .to.emit(hub, "TokenRouterSet")
                .withArgs(tokenRouter.target);
            expect(await hub.tokenRouter()).to.equal(tokenRouter.target);
        });

        it("Should prevent non-owners from setting the token router", async function () {
            await expect(hub.connect(addr1).setTokenRouter(tokenRouter.target))
                .to.be.revertedWith("Ownable: caller is not the owner");
        });

        it("Should prevent setting the token router to the zero address", async function () {
            await expect(hub.setTokenRouter(ethers.ZeroAddress))
                .to.be.revertedWith("Hub: Router address cannot be zero");
        });
    });

    describe("Module Registration", function () {
        const moduleId = ethers.id("LUNA_COMICS_MODULE");

        it("Should allow the owner to register a new module", async function () {
            await expect(hub.registerModule(moduleId, orchestrator.target, ft.target, nft.target))
                .to.emit(hub, "ModuleRegistered")
                .withArgs(moduleId, orchestrator.target);

            const storedModule = await hub.getModule(moduleId);
            expect(storedModule.orchestrator).to.equal(orchestrator.target);
            expect(storedModule.ft).to.equal(ft.target);
            expect(storedModule.nft).to.equal(nft.target);
            expect(storedModule.isActive).to.be.true;
        });

        it("Should prevent non-owners from registering a module", async function () {
            await expect(hub.connect(addr1).registerModule(moduleId, orchestrator.target, ft.target, nft.target))
                .to.be.revertedWith("Ownable: caller is not the owner");
        });

        it("Should prevent registering a module with an existing ID", async function () {
            await hub.registerModule(moduleId, orchestrator.target, ft.target, nft.target);
            await expect(hub.registerModule(moduleId, orchestrator.target, ft.target, nft.target))
                .to.be.revertedWith("Hub: Module ID already exists");
        });
    });

    describe("Module Removal", function () {
        const moduleId = ethers.id("LUNA_COMICS_MODULE");

        beforeEach(async function() {
            await hub.registerModule(moduleId, orchestrator.target, ft.target, nft.target);
        });

        it("Should allow the owner to remove (deactivate) a module", async function () {
            await expect(hub.removeModule(moduleId))
                .to.emit(hub, "ModuleRemoved")
                .withArgs(moduleId);
            
            const storedModule = await hub.getModule(moduleId);
            expect(storedModule.isActive).to.be.false;
        });

        it("Should prevent non-owners from removing a module", async function () {
            await expect(hub.connect(addr1).removeModule(moduleId))
                .to.be.revertedWith("Ownable: caller is not the owner");
        });

        it("Should revert when trying to remove a non-existent module", async function () {
            const nonExistentModuleId = ethers.id("NON_EXISTENT_MODULE");
            await expect(hub.removeModule(nonExistentModuleId))
                .to.be.revertedWith("Hub: Module not found");
        });
    });
});
