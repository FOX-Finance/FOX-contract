const { signer, contract, set, attach } = require('./set');

async function mintWETH() {
    let txRes;

    process.stdout.write("[WETH] Mint");
    txRes = await contract.weth.connect(signer.owner).mint(
        signer.user.address,
        BigInt(122.7 * (10 ** 18))
    );
    await txRes.wait();
    console.log(" - complete");
}

async function mintFOXS() {
    let txRes;

    process.stdout.write("[FOXS] Mint");
    txRes = await contract.foxs.connect(signer.owner).mint(
        signer.user.address,
        BigInt(327.0 * (10 ** 18))
    );
    await txRes.wait();
    console.log(" - complete");
}

async function mintFOXS2() {
    let txRes;

    process.stdout.write("[FOXS] Mint to user2");
    txRes = await contract.foxs.connect(signer.owner).mint(
        signer.user2.address,
        BigInt(1000.0 * (10 ** 18))
    );
    await txRes.wait();
    console.log(" - complete");
}

async function main() {
    console.log("\n<Set>");
    await set();

    console.log("\n<Attach>");
    await attach();

    console.log("\n<Mint WETH>");
    await mintWETH();

    console.log("\n<Mint FOXS>");
    await mintFOXS();

    console.log("\n<Mint FOXS2>");
    await mintFOXS2();
}

// run
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
