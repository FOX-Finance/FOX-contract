let signer = {
    "owner": null,
    "bot": null,
    "feeTo": null,
    "user": null
};

let contract = {
    "oracleFeeder": null,
    "weth": null,
    "nis": null,
    "sin": null,
    "foxs": null,
    "fox": null,
    "coupon": null,
    "foxFarm": null
};

async function set() {
    [signer.owner, signer.bot, signer.feeTo, signer.user] = await ethers.getSigners();

    let balanceOfOwner = await signer.owner.getBalance() / (10 ** 18);
    let balanceOfBot = await signer.bot.getBalance() / (10 ** 18);
    let balanceOfFeeTo = await signer.feeTo.getBalance() / (10 ** 18);
    let balanceOfUser = await signer.user.getBalance() / (10 ** 18);

    console.log("Owner:\t", signer.owner.address, `(${balanceOfOwner} ETH)`);
    console.log("Bot:\t", signer.bot.address, `(${balanceOfBot} ETH)`);
    console.log("FeeTo:\t", signer.feeTo.address, `(${balanceOfFeeTo} ETH)`);
    console.log("User:\t", signer.user.address, `(${balanceOfUser} ETH)`);
}

async function attach() {
    const address = require("../address");

    process.stdout.write("Attach WETH");
    contract.weth = await ethers.getContractAt("WETH", address.WETH);
    console.log(" - complete");

    process.stdout.write("Attach FOXS");
    contract.foxs = await ethers.getContractAt("FOXS", address.FOXS);
    console.log(" - complete");

    process.stdout.write("Attach FOX");
    contract.fox = await ethers.getContractAt("FOX", address.FOX);
    console.log(" - complete");

    process.stdout.write("Attach FoxFarm");
    contract.foxFarm = await ethers.getContractAt("FoxFarm", address.FoxFarm);
    console.log(" - complete");

    process.stdout.write("Attach OracleFeeder");
    contract.oracleFeeder = await ethers.getContractAt("OracleFeeder", address.OracleFeeder);
    console.log(" - complete");
}

module.exports = {
    signer,
    contract,
    set,
    attach
}
