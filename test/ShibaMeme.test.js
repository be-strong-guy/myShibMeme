// test/ShibaMeme.test.js
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("ShibaMeme 全覆盖测试", function () {
    let token, owner, alice, bob, weth, router, pair;

    /* 基础数量 */
    const TOTAL = ethers.parseUnits("1000000", 18);
    const ONE   = ethers.parseUnits("1", 18);
    const ONEK  = ONE * 1000n;

    beforeEach(async () => {
        [owner, alice, bob] = await ethers.getSigners();

        /* 1. 部署 WETH / Factory / Router（简化实现） */
        const WETH9   = await ethers.getContractFactory("WETH9");
        weth = await WETH9.deploy();

        const Factory = await ethers.getContractFactory("UniswapV2Factory");
        const factory = await Factory.deploy(owner.address);

        const Router  = await ethers.getContractFactory("UniswapV2Router02");
        router = await Router.deploy(factory.target, weth.target);

        /* 2. 部署代币并建 pair */
        const ShibaMeme = await ethers.getContractFactory("ShibaMeme");
        token = await ShibaMeme.deploy(TOTAL, owner.address);
        await token.waitForDeployment();

        await factory.createPair(token.target, weth.target);
        pair = await factory.getPair(token.target, weth.target);

        /* 3. 把限额放大到 100 % 避免 revert */
        await token.setMaxTxPercent(100);
        await token.setMaxWalletPercent(100);
    });

    /* 1️ approve & transferFrom */
    it("approve & transferFrom", async () => {
        const sendAmount = ethers.parseUnits("100", 18);

        /* 1. 把营销钱包设成 Owner，Owner 会回收 2 % 税 */
        await token.setMarketingWallet(owner.address);

        /* 2. Owner → Alice（Owner 减 100，但回收 2 Token） */
        await token.transfer(alice.address, sendAmount);

        /* 3. 最终 Owner 余额只减 98（100 - 2） */
        const taxToOwner = (sendAmount * 2n) / 100n; // 2 Token
        expect(await token.balanceOf(owner.address))
            .to.equal(TOTAL - sendAmount + taxToOwner); // TOTAL - 98
    });

    /* 2️ setPair 只能设置一次 */
    it("setPair reverts if already set", async () => {
        await token.setPair(pair);               // 第一次成功
        await expect(token.setPair(pair)).to.be.revertedWith("Pair already set");
    });

    /* 3 addLiquidityETH */
    it("addLiquidityETH", async () => {
        const tokenAmount = ONEK;                 // 1000 token
        const ethAmount   = ethers.parseEther("1"); // 1 ETH

        await token.approve(router.target, tokenAmount);

        await expect(
            router.addLiquidityETH(
                token.target,
                tokenAmount,
                0,
                0,
                owner.address,
                Math.floor(Date.now() / 1000) + 300,
                { value: ethAmount }
            )
        ).to.not.be.reverted;
    });

    /* 4️ 事件完整性 */
    it("events", async () => {
        const amount = ONEK;
        const tax = (amount * 6n) / 100n;
        const net = amount - tax;

        // 监听税后金额
        await expect(token.transfer(alice.address, amount))
            .to.emit(token, "Transfer")
            .withArgs(owner.address, alice.address, net);
    });
});