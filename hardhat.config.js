require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.28",
    networks: {
        sepolia: {
            url: "https://rpc.sepolia.org",
            accounts: ["xxxx"]
        }
    }
};
