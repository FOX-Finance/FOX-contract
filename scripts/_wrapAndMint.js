const env = require("../env");

let signer = { "owner": null, "oracleFeeder": null, "feeTo": null, "user": null };
let contract = { "weth": null, "nis": null, "sin": null, "foxs": null, "fox": null, "coupon": null, "foxFarm": null };

async function set() {
    [signer.owner, signer.oracleFeeder, signer.feeTo, signer.user] = await ethers.getSigners(); // main/test-net

    let balanceOfOwner = await signer.owner.getBalance();
    console.log("Deployer:\t", signer.owner.address, `(${balanceOfOwner})`);
    console.log("OracleFeeder:\t", signer.oracleFeeder.address);
    console.log("FeeTo:\t\t", signer.feeTo.address);
    console.log("User:\t\t", signer.user.address);
}

async function attach() {
    process.stdout.write("Attach WETH");
    contract.weth = await ethers.getContractAt("WETH", env.WETH);
    console.log(" complete");

    process.stdout.write("Attach FOXS");
    contract.foxs = await ethers.getContractAt("FOXS", env.FOXS);
    console.log(" complete");
}

async function wrap() {
    let txRes;

    process.stdout.write("[WETH] Deposit");
    txRes = await contract.weth.connect(signer.user).deposit({ value: BigInt(0.01 * (10 ** 18)) });
    await txRes.wait();
    console.log(" - complete");
}

async function mint() {
    let txRes;

    process.stdout.write("[FOXS] Mint");
    txRes = await contract.foxs.connect(signer.owner).mint(
        signer.user.address,
        BigInt(1 * (10 ** 18))
    );
    await txRes.wait();
    console.log(" - complete");
}

async function main() {
    console.log("\n<Set>");
    await set();

    console.log("\n<Attach>");
    await attach();

    console.log("\n<Wrap>");
    await wrap();

    console.log("\n<Mint>");
    await mint();
}

// run
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
