const { signer, contract, set, attach } = require('./set');

async function updatePrice(price, confidence) {
    process.stdout.write("[OracleFeeder] Update FOX price");
    const beforePrice = await contract.fox.getStablePrice();
    const txRes = await contract.oracleFeeder.connect(signer.bot).updateStablePrice(
        price,
        confidence
    );
    await txRes.wait();
    const afterPrice = await contract.fox.getStablePrice();
    console.log(` - complete: ${beforePrice} -> ${afterPrice}`);
}

async function getTrustLevel() {
    process.stdout.write("[Fox] Get trust level");
    const trustLevel = await contract.fox.trustLevel();
    console.log(" - complete:\t", trustLevel / 100, "%");
}

async function main() {
    console.log("\n<Set>");
    await set();

    console.log("\n<Attach>");
    await attach();

    console.log("\n<Update FOX price>");
    await updatePrice(
        BigInt(1.1 * 10000),
        BigInt(0)
    );

    console.log("\n<Get trust level>");
    await getTrustLevel();
}

// run
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
