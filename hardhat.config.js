require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.28",
    networks: {
        sepolia: {
            url: "https://rpc.sepolia.org",
            accounts: ["e98cb1789d5f672c5c2f019e993f537ba0a76ab5c21f70d006dcef0004c71368"]
        }
    }
};
