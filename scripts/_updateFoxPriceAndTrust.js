const { signer, contract, set, attach } = require('./set');

async function updateFoxPrice(price) {
    let txRes;

    process.stdout.write("[FOX] Update FOX price");
    txRes = await contract.fox.connect(signer.oracleFeeder).updateStablePrice(
        BigInt(price), BigInt(0)
    );
    await txRes.wait();
    console.log(":\t", await contract.fox.connect(signer.oracleFeeder).getStablePrice());
}

async function updateTrustLevel() {
    let txRes;

    process.stdout.write("[FOX] Update trust");
    txRes = await contract.fox.connect(signer.owner).updateTrustLevel();
    await txRes.wait();
    console.log(":\t", await contract.fox.trustLevel());
}

async function main() {
    console.log("\n<Set>");
    await set();

    console.log("\n<Attach>");
    await attach();

    // console.log("\n<Update FOX Price>");
    // await updateFoxPrice(10010);

    // console.log("\n<Update Trust Level>");
    // await updateTrustLevel();
}

// run
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
