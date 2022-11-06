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
  defaultNetwork: 'localhost',
  networks: {
    hardhat: {
      forking: {
        enabled: true,
        url: 'https://data-seed-prebsc-2-s2.binance.org:8545',
        // blockNumber: 24243078,
        accounts: [
          process.env.PRIVATE_KEY_OWNER,
          process.env.PRIVATE_KEY_BOT,
          process.env.PRIVATE_KEY_FEE_TO,
          process.env.PRIVATE_KEY_USER,
          process.env.PRIVATE_KEY_USER_2
        ],
      },
    },
    localhost: {
      url: 'http://127.0.0.1:8545',
      accounts: [
        process.env.PRIVATE_KEY_OWNER,
        process.env.PRIVATE_KEY_BOT,
        process.env.PRIVATE_KEY_FEE_TO,
        process.env.PRIVATE_KEY_USER,
        process.env.PRIVATE_KEY_USER_2
      ],
    },
    bscTestnet: {
      url: 'https://data-seed-prebsc-2-s2.binance.org:8545',
      accounts: [
        process.env.PRIVATE_KEY_OWNER,
        process.env.PRIVATE_KEY_BOT,
        process.env.PRIVATE_KEY_FEE_TO,
        process.env.PRIVATE_KEY_USER,
        process.env.PRIVATE_KEY_USER_2
      ],
    },
  },
};
