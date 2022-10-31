const fs = require('fs');

let signer = { "owner": null, "oracleFeeder": null, "feeTo": null };
let contract = { "weth": null, "nis": null, "sin": null, "foxs": null, "fox": null, "coupon": null, "foxFarm": null };

async function set() {
    [signer.owner, signer.oracleFeeder, signer.feeTo] = await ethers.getSigners(); // main/test-net

    let balanceOfOwner = await signer.owner.getBalance() / (10**18);
    console.log("Deployer:\t", signer.owner.address, `(${balanceOfOwner} ETH)`);
    console.log("OracleFeeder:\t", signer.oracleFeeder.address);
    console.log("FeeTo:\t\t", signer.feeTo.address);
}

async function deploy() {
    process.stdout.write("Deploy WETH");
    const WETH = await ethers.getContractFactory("WETH", signer.owner);
    contract.weth = await WETH.deploy();
    await contract.weth.deployed();
    console.log(":\t", contract.weth.address);

    process.stdout.write("Deploy NIS");
    const NIS = await ethers.getContractFactory("NIS", signer.owner);
    contract.nis = await NIS.deploy();
    await contract.nis.deployed();
    console.log(":\t", contract.nis.address);

    process.stdout.write("Deploy SIN");
    const SIN = await ethers.getContractFactory("SIN", signer.owner);
    contract.sin = await SIN.deploy(contract.nis.address);
    await contract.sin.deployed();
    console.log(":\t", contract.sin.address);

    process.stdout.write("Deploy FOXS");
    const FOXS = await ethers.getContractFactory("FOXS", signer.owner);
    contract.foxs = await FOXS.deploy();
    await contract.foxs.deployed();
    console.log(":\t", contract.foxs.address);

    process.stdout.write("Deploy FOX");
    const FOX = await ethers.getContractFactory("FOX", signer.owner);
    contract.fox = await FOX.deploy(
        signer.oracleFeeder.address, signer.feeTo.address, contract.sin.address, contract.foxs.address,
        20, 45, 75
    );
    await contract.fox.deployed();
    console.log(":\t", contract.fox.address);

    process.stdout.write("Deploy Coupon");
    const Coupon = await ethers.getContractFactory("Coupon", signer.owner);
    contract.coupon = await Coupon.deploy(signer.feeTo.address, contract.nis.address, 0);
    await contract.coupon.deployed();
    console.log(":\t", contract.coupon.address);

    process.stdout.write("Deploy FoxFarm");
    const FoxFarm = await ethers.getContractFactory("FoxFarm", signer.owner);
    contract.foxFarm = await FoxFarm.deploy(
        signer.oracleFeeder.address, signer.feeTo.address,
        contract.weth.address, contract.sin.address, contract.foxs.address, contract.fox.address, contract.coupon.address,
        7000, ethers.constants.MaxUint256, 200
    );
    await contract.foxFarm.deployed();
    console.log(":\t", contract.foxFarm.address);

    fs.writeFileSync("env.json", JSON.stringify({
        "WETH": contract.weth.address,
        "NIS": contract.nis.address,
        "SIN": contract.sin.address,
        "FOXS": contract.foxs.address,
        "FOX": contract.fox.address,
        "Coupon": contract.coupon.address,
        "FoxFarm": contract.foxFarm.address
    }, null, 4));
}

async function init() {
    let txRes;

    process.stdout.write("[FOX] Add allowlist oracleFeeder");
    txRes = await contract.fox.connect(signer.owner).addAllowlist(signer.oracleFeeder.address);
    await txRes.wait();
    console.log(" - complete");

    process.stdout.write("[SIN] Change SIN's owner to FoxFarm");
    txRes = await contract.sin.connect(signer.owner).transferOwnership(contract.foxFarm.address);
    await txRes.wait();
    console.log(" - complete");
}

async function main() {
    console.log("\n<Set>");
    await set();

    console.log("\n<Deploy>");
    await deploy();

    console.log("\n<Init>");
    await init();
}

// run
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
