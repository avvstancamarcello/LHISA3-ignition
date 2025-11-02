const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");

describe("SolidarySwapper Integration Test", function () {
    let owner, user;
    let cosmixToken, wethToken;
    let uniswapV2Factory, uniswapV2Router;
    let solidarySwapper;

    // Uniswap V2 Router address for Hardhat local network (a common one, but we deploy our own)
    const UNISWAP_ROUTER_ADDRESS = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D";

    beforeEach(async function () {
        [owner, user] = await ethers.getSigners();

        // Deploy a mock WETH token
        const WETHFactory = await ethers.getContractFactory("contracts/mocks/WETH9.sol:WETH9");
        wethToken = await WETHFactory.deploy();
        await wethToken.waitForDeployment();

        // Deploy our CosmixProtocolToken
                const CosmixTokenFactory = await ethers.getContractFactory("CosmixSolidaryToken");
        cosmixToken = await upgrades.deployProxy(CosmixTokenFactory, [owner.address, ethers.parseEther("1000000"), owner.address], { initializer: 'initialize' });
        await cosmixToken.waitForDeployment();

        // Deploy Uniswap V2 Factory
        const UniswapV2Factory = await ethers.getContractFactory("contracts/mocks/uniswap/UniswapV2Factory.sol:UniswapV2Factory");
        uniswapV2Factory = await UniswapV2Factory.deploy(owner.address);
        await uniswapV2Factory.waitForDeployment();

        // Deploy Uniswap V2 Router
        const UniswapV2RouterFactory = await ethers.getContractFactory("contracts/mocks/uniswap/UniswapV2Router02.sol:UniswapV2Router02");
        uniswapV2Router = await UniswapV2RouterFactory.deploy(uniswapV2Factory.target, wethToken.target);
        await uniswapV2Router.waitForDeployment();

        // Deploy our SolidarySwapper
        const SwapperFactory = await ethers.getContractFactory("contracts/utils/SolidarySwapper.sol:SolidarySwapper");
        solidarySwapper = await upgrades.deployProxy(SwapperFactory, [uniswapV2Router.target], { initializer: 'initialize' });
        await solidarySwapper.waitForDeployment();

        // Mint some Cosmix tokens to the user for the test
        await cosmixToken.mint(user.address, ethers.parseEther("1000"));

        // Create a liquidity pool for Cosmix/WETH
        const cosmixAmount = ethers.parseEther("500");
        const wethAmount = ethers.parseEther("10");

        // Approve the router to spend tokens
        await cosmixToken.approve(uniswapV2Router.target, cosmixAmount);
        await wethToken.deposit({ value: wethAmount });
        await wethToken.approve(uniswapV2Router.target, wethAmount);
        
        // Manually create the pair through the factory to ensure it exists before adding liquidity
        await uniswapV2Factory.createPair(cosmixToken.target, wethToken.target);
        
        // Add liquidity
        await uniswapV2Router.addLiquidity(
            cosmixToken.target,
            wethToken.target,
            cosmixAmount,
            wethAmount,
            0,
            0,
            owner.address,
            Math.floor(Date.now() / 1000) + 60 * 10 // 10 minutes from now
        );
    });

    it("Should deploy all contracts correctly", async function () {
        expect(solidarySwapper.target).to.be.properAddress;
        expect(await solidarySwapper.uniswapV2Router()).to.equal(uniswapV2Router.target);
    });

    it("Should allow a user to swap CosmixToken for WETH", async function () {
        const amountIn = ethers.parseEther("100");
        
        // User approves the SolidarySwapper to spend their Cosmix tokens
        await cosmixToken.connect(user).approve(solidarySwapper.target, amountIn);

        const path = [cosmixToken.target, wethToken.target];
        const amountsOut = await uniswapV2Router.getAmountsOut(amountIn, path);
        const amountOutMin = amountsOut[1];

        const userWethBalanceBefore = await wethToken.balanceOf(user.address);
        const userCosmixBalanceBefore = await cosmixToken.balanceOf(user.address);

        // Execute the swap via our SolidarySwapper
        await expect(solidarySwapper.connect(user).swapExactTokensForTokens(
            cosmixToken.target,
            wethToken.target,
            amountIn,
            amountOutMin,
            user.address,
            Math.floor(Date.now() / 1000) + 60 * 10
        )).to.emit(solidarySwapper, "SwapExecuted");

        const userWethBalanceAfter = await wethToken.balanceOf(user.address);
        const userCosmixBalanceAfter = await cosmixToken.balanceOf(user.address);

        // Check balances
        expect(userWethBalanceAfter).to.be.gt(userWethBalanceBefore);
        expect(userCosmixBalanceAfter).to.equal(userCosmixBalanceBefore - amountIn);
        expect(userWethBalanceAfter).to.equal(amountOutMin); // In a direct swap, this should be the amount received
    });

    it("Should fail if the user has not approved the swapper", async function () {
        const amountIn = ethers.parseEther("100");
        const path = [cosmixToken.target, wethToken.target];
        const amountsOut = await uniswapV2Router.getAmountsOut(amountIn, path);
        const amountOutMin = amountsOut[1];

        // Note: No approval is given here

        await expect(solidarySwapper.connect(user).swapExactTokensForTokens(
            cosmixToken.target,
            wethToken.target,
            amountIn,
            amountOutMin,
            user.address,
            Math.floor(Date.now() / 1000) + 60 * 10
        )).to.be.revertedWith("ERC20: insufficient allowance");
    });
});
