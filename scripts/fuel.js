const { signer, contract, set, attach } = require('./set');

async function mintWETH() {
    let txRes;

    process.stdout.write("[WETH] Mint");
    txRes = await contract.weth.connect(signer.owner).mint(
        signer.user.address,
        BigInt(10000 * (10 ** 18))
    );
    await txRes.wait();
    console.log(" - complete");
}

async function mintWETH2() {
    let txRes;

    process.stdout.write("[WETH] Mint to user2");
    txRes = await contract.weth.connect(signer.owner).mint(
        signer.user2.address,
        BigInt(10000 * (10 ** 18))
    );
    await txRes.wait();
    console.log(" - complete");
}

async function transferFOXS() {
    let txRes;

    process.stdout.write("[FOXS] Transfer");
    txRes = await contract.foxs.connect(signer.owner).transfer(
        signer.user.address,
        BigInt(10000 * (10 ** 18))
    );
    await txRes.wait();
    console.log(" - complete");
}

async function transferFOXS2() {
    let txRes;

    process.stdout.write("[FOXS] Transfer to user2");
    txRes = await contract.foxs.connect(signer.owner).transfer(
        signer.user2.address,
        BigInt(10000 * (10 ** 18))
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

    console.log("\n<Mint WETH2>");
    await mintWETH2();

    console.log("\n<Transfer FOXS>");
    await transferFOXS();

    console.log("\n<Transfer FOXS2>");
    await transferFOXS2();
}

// run
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
