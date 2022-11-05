dotenv -e .env.test -- npx hardhat run scripts/deploy.js --network localhost
dotenv -e .env.test -- npx hardhat run scripts/fuel.js --network localhost
dotenv -e .env.test -- npx hardhat run scripts/mint.js --network localhost
dotenv -e .env.test -- npx hardhat run scripts/redeem.js --network localhost
