const hre = require("hardhat");
async function main() {
    const [deployer] = await hre.ethers.getSigners();
    const ShibaMeme = await hre.ethers.getContractFactory("ShibaMeme");
    const token = await ShibaMeme.deploy(
        1000000,               // 初始总量 1,000,000 SHIBME
        deployer.address       // 营销钱包先用部署者
    );
    await token.deployed();
    console.log("Token deployed to:", token.address);
}
main().catch((error) => { console.error(error); process.exitCode = 1; });