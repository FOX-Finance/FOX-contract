require('dotenv').config();

require("@nomicfoundation/hardhat-toolbox");

accounts = [
  process.env.PRIVATE_KEY_OWNER,
  process.env.PRIVATE_KEY_BOT,
  process.env.PRIVATE_KEY_FEE_TO,
  process.env.PRIVATE_KEY_USER,
  process.env.PRIVATE_KEY_USER_2
];

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
  defaultNetwork: 'calibrationnet',
  networks: {
    hardhat: {
      // forking: {
      //   enabled: true,
      //   url: "https://api.calibration.node.glif.io/rpc/v1",
      // },
    },
    localhost: {
      url: 'http://127.0.0.1:8545',
    },
    calibrationnet: {
      chainId: 314159,
      url: "https://api.calibration.node.glif.io/rpc/v1",
      accounts: accounts,
    },
    filecoinmainnet: {
      chainId: 314,
      url: "https://api.node.glif.io",
      accounts: accounts,
    },
  },
};
