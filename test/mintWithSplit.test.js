const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("LunaComics mintWithSplit", function () {
  let LunaComics, OceanMangaNFT, lunaComics, oceanMangaNFT, owner, user;

  beforeEach(async () => {
    [owner, user] = await ethers.getSigners();

    // Deploy OceanMangaNFT
    const OceanMangaNFTFactory = await ethers.getContractFactory("OceanMangaNFT");
    oceanMangaNFT = await OceanMangaNFTFactory.deploy();
    await oceanMangaNFT.initialize(owner.address, "https://baseuri/", owner.address);

    // Deploy LunaComics
    const LunaComicsFactory = await ethers.getContractFactory("LunaComics");
    lunaComics = await LunaComicsFactory.deploy();
    await lunaComics.initialize(owner.address, 0, owner.address);

    // Set NFT contract in LunaComics
    await lunaComics.setOceanMangaNFT(oceanMangaNFT.target);

    // Grant MINTER_ROLE to LunaComics for OceanMangaNFT
    const MINTER_ROLE = await oceanMangaNFT.MINTER_ROLE();
    await oceanMangaNFT.grantRole(MINTER_ROLE, lunaComics.target);
  });

  it("should mint FT and NFT with price split", async () => {
    const ftAmount = ethers.parseUnits("100", 18);
    const nftId = 1;
    const nftAmount = 1;
    const nftData = "0x";
    const price = ethers.parseEther("1");

    await expect(
      lunaComics.connect(user).mintWithSplit(ftAmount, nftId, nftAmount, nftData, { value: price })
    ).to.emit(lunaComics, "MintWithSplit");

    // Check FT balance
    const ftBalance = await lunaComics.balanceOf(user.address);
    expect(ftBalance).to.equal(ftAmount);

    // Check NFT balance
    const nftBalance = await oceanMangaNFT.balanceOf(user.address, nftId);
    expect(nftBalance).to.equal(nftAmount);
  });
});
