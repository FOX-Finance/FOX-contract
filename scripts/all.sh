# Set & Fuel
dotenv -e .env.test -- npx hardhat run scripts/deploy.js --network localhost
dotenv -e .env.test -- npx hardhat run scripts/fuel.js --network localhost

# Mint
dotenv -e .env.test -- npx hardhat run scripts/mint.js --network localhost

# Burn
# dotenv -e .env.test -- npx hardhat run scripts/redeem.js --network localhost

# Buyback
for ((i=0;i<15;i++))
do
    echo "Running loop "$i
    curl http://localhost:8545 -H\
        "Content-type: application/json"\
        --data '{"jsonrpc":"2.0","method":"evm_increaseTime","params":[361000], "id": 1}' # increase time
    curl http://localhost:8545 -H\
        "Content-type: application/json"\
        --data '{"jsonrpc":"2.0","method":"hardhat_mine","params":["0x1"], "id": 1}' # mine one block
    echo ""
    dotenv -e .env.test -- npx hardhat run scripts/oracle.js --network localhost # set FOX price
done
dotenv -e .env.test -- npx hardhat run scripts/buyback.js --network localhost

# Recoll
# dotenv -e .env.test -- npx hardhat run scripts/recoll.js --network localhost
