require('dotenv').config();

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
        enabled: true,
        url: 'https://data-seed-prebsc-1-s1.binance.org:8545',
        accounts: [
          process.env.PRIVATE_KEY_OWNER,
          process.env.PRIVATE_KEY_BOT,
          process.env.PRIVATE_KEY_FEE_TO,
          process.env.PRIVATE_KEY_USER
        ],
      },
    },
    localhost: {
      url: 'http://127.0.0.1:8545',
      accounts: [
        process.env.PRIVATE_KEY_OWNER,
        process.env.PRIVATE_KEY_BOT,
        process.env.PRIVATE_KEY_FEE_TO,
        process.env.PRIVATE_KEY_USER
      ],
    },
    bscTestnet: {
      url: 'https://data-seed-prebsc-1-s1.binance.org:8545',
      accounts: [
        process.env.PRIVATE_KEY_OWNER,
        process.env.PRIVATE_KEY_BOT,
        process.env.PRIVATE_KEY_FEE_TO,
        process.env.PRIVATE_KEY_USER
      ],
    },
  },
};
