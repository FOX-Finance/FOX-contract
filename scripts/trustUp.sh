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
    dotenv -e .env.test -- npx hardhat run scripts/oracleUp.js --network localhost # set FOX price
done
