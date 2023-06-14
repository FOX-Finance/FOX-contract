# Set & Fuel
dotenv -e .env.test -- npx hardhat run scripts/deploy.js
dotenv -e .env.test -- npx hardhat run scripts/fuel.js

# Mint
dotenv -e .env.test -- npx hardhat run scripts/mint.js


# # Redeem
# dotenv -e .env.test -- npx hardhat run scripts/redeem.js


# # Buyback
# for ((i=0;i<10;i++))
# do
#     echo "Running loop "$i
#     curl http://localhost:8545 -H\
#         "Content-type: application/json"\
#         --data '{"jsonrpc":"2.0","method":"evm_increaseTime","params":[361000], "id": 1}' # increase time
#     curl http://localhost:8545 -H\
#         "Content-type: application/json"\
#         --data '{"jsonrpc":"2.0","method":"hardhat_mine","params":["0x1"], "id": 1}' # mine one block
#     echo ""
#     dotenv -e .env.test -- npx hardhat run scripts/oracleUp.js # set FOX price
# done
# dotenv -e .env.test -- npx hardhat run scripts/buyback.js


# # Recoll
# for ((i=0;i<10;i++))
# do
#     echo "Running loop "$i
#     curl http://localhost:8545 -H\
#         "Content-type: application/json"\
#         --data '{"jsonrpc":"2.0","method":"evm_increaseTime","params":[361000], "id": 1}' # increase time
#     curl http://localhost:8545 -H\
#         "Content-type: application/json"\
#         --data '{"jsonrpc":"2.0","method":"hardhat_mine","params":["0x1"], "id": 1}' # mine one block
#     echo ""
#     dotenv -e .env.test -- npx hardhat run scripts/oracleDown.js # set FOX price
# done
# dotenv -e .env.test -- npx hardhat run scripts/recoll.js


# Coupon
for ((i=0;i<10;i++))
do
    echo "Running loop "$i
    curl http://localhost:8545 -H\
        "Content-type: application/json"\
        --data '{"jsonrpc":"2.0","method":"evm_increaseTime","params":[361000], "id": 1}' # increase time
    curl http://localhost:8545 -H\
        "Content-type: application/json"\
        --data '{"jsonrpc":"2.0","method":"hardhat_mine","params":["0x1"], "id": 1}' # mine one block
    echo ""
    dotenv -e .env.test -- npx hardhat run scripts/oracleUp.js # set FOX price
done
dotenv -e .env.test -- npx hardhat run scripts/coupon.js
