const { signer, contract, set, attach } = require('./set');

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
