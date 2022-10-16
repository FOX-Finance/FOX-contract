const data = require("./config");

require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.9",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  paths: {
    sources: './contracts',
  },
  defaultNetwork: 'mumbai',
  networks: {
    hardhat: {},
    mumbai: {
      url: 'https://rpc-mumbai.maticvigil.com',
      accounts: [data.privateKey],
    },
  },
};
