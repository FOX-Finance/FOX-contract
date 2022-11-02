require('dotenv').config();
const axios = require('axios');

const web3ApiKey = process.env.API_KEY_MORALIS;
const WBNB = process.env.ADDRESS_WBNB;

const options = {
    method: 'GET',
    url: `https://deep-index.moralis.io/api/v2/erc20/${WBNB}/price`,
    params: {
        chain: 'bsc',
        // to_block: '',
        // exchange: '',
    },
    headers: {
        accept: 'application/json',
        'X-API-Key': web3ApiKey,
    }
};

axios
    .request(options)
    .then(function (response) {
        console.log(response.data);
        console.log(response.data.usdPrice);
    })
    .catch(function (error) {
        console.error(error);
    });

// const res = {
//     "nativePrice": {
//         "value": "1019400740872569653",
//         "decimals": 18,
//         "name": "Binance Coin",
//         "symbol": "BNB"
//     },
//     "usdPrice": 325.47900295628267,
//     "exchangeAddress": "0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73",
//     "exchangeName": "PancakeSwap v2"
// }
