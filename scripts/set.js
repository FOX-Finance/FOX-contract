const env = require("../env");

let signer = {
    "owner": null,
    "oracleFeeder": null,
    "feeTo": null,
    "user": null
};

let contract = {
    "weth": null,
    "nis": null,
    "sin": null,
    "foxs": null,
    "fox": null,
    "coupon": null,
    "foxFarm": null
};

async function set() {
    [signer.owner, signer.oracleFeeder, signer.feeTo, signer.user] = await ethers.getSigners(); // main/test-net

    let balanceOfOwner = await signer.owner.getBalance() / (10 ** 18);
    console.log("Owner:\t\t", signer.owner.address, `(${balanceOfOwner} ETH)`);
    console.log("OracleFeeder:\t", signer.oracleFeeder.address);
    console.log("FeeTo:\t\t", signer.feeTo.address);
    console.log("User:\t\t", signer.user.address);
}

async function attach() {
    process.stdout.write("Attach WETH");
    contract.weth = await ethers.getContractAt("WETH", env.WETH);
    console.log(" - complete");

    process.stdout.write("Attach FOXS");
    contract.foxs = await ethers.getContractAt("FOXS", env.FOXS);
    console.log(" - complete");

    process.stdout.write("Attach FOX");
    contract.fox = await ethers.getContractAt("FOX", env.FOX);
    console.log(" - complete");
}

module.exports = {
    signer,
    contract,
    set,
    attach
}
