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
  defaultNetwork: 'hardhat',
  networks: {
    hardhat: {
      forking: {
        url: 'https://data-seed-prebsc-1-s1.binance.org:8545',
        accounts: [data.owner, data.oracleFeeder, data.feeTo, data.user],
      },
    },
    localhost: {
      url: 'http://127.0.0.1:8545',
      accounts: [data.owner, data.oracleFeeder, data.feeTo, data.user],
    },
    bscTestnet: {
      url: 'https://data-seed-prebsc-1-s1.binance.org:8545',
      accounts: [data.owner, data.oracleFeeder, data.feeTo, data.user],
    },
  },
};
