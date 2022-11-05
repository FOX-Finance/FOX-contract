const { signer, contract, set, attach } = require('./set');

async function getTrustLevel() {
    process.stdout.write("[Fox] Get trust level");
    const trustLevel = await contract.fox.trustLevel();
    console.log(" - complete:\t", trustLevel / 100, "%");
}

async function approveFOXS() {
    let txRes;
    let allowance;

    process.stdout.write("[FOXS] Check allowance");
    allowance = await contract.foxs.allowance(signer.user.address, contract.foxFarm.address);
    console.log(" - complete:\t", allowance / (10 ** 18));

    if (allowance == 0) {
        process.stdout.write("[FOXS] Max approve");
        txRes = await contract.foxs.connect(signer.user).approveMax(contract.foxFarm.address);
        await txRes.wait();
        console.log(" - complete");

        process.stdout.write("[FOXS] Check allowance");
        allowance = await contract.foxs.allowance(signer.user.address, contract.foxFarm.address);
        console.log(" - complete:\t", allowance / (10 ** 18));
    }
}

async function getLtv(id) {
    process.stdout.write("[FoxFarm] Get current LTV");
    const ltv = await contract.foxFarm.currentLTV(id);
    console.log(" - complete:\t", ltv / 100, "%");

    return ltv;
}

async function getBuybackAmount(id, ltv, shareAmount) {
    process.stdout.write("[FoxFarm] Get collateral amount");
    const collateralAmount = await contract.foxFarm.exchangedCollateralAmountFromShareToLtv(id, ltv, shareAmount);
    console.log(" - complete:\t", collateralAmount / (10 ** 18));

    return collateralAmount;
}

async function getLtvRange(id, stableAmount) {
    process.stdout.write("[FoxFarm] Get LTV range");
    const res = await contract.foxFarm.ltvRangeWhenBuyback(id, stableAmount);
    console.log(" - complete:");
    console.log("\tupperBound:\t", res.upperBound_ / 100, "%");
    console.log("\tlowerBound:\t", res.lowerBound_ / 100, "%");
}

async function main() {
    console.log("\n<Set>");
    await set();

    console.log("\n<Attach>");
    await attach();

    console.log("\n<Approve FOXS>");
    await approveFOXS();

    console.log("\n<Get trust level>");
    await getTrustLevel();

    console.log("\n<Get current LTV>");
    const ltv = await getLtv(
        BigInt(0)
    );

    console.log("\n<Get buyback amount>");
    const collateralAmount = await getBuybackAmount(
        BigInt(0),
        ltv,
        BigInt(10 * (10 ** 18)),
    );

    console.log("\n<Get LTV range>");
    await getLtvRange(
        BigInt(0),
        BigInt(4 * (10 ** 18)),
    );

    console.log("\n<Get buyback amount w/ different LTV>");
    const collateralAmountWithLtv = await getBuybackAmount(
        BigInt(0),
        BigInt(25 * 100),
        BigInt(10 * (10 ** 18)),
    );

    console.log("\n<Buyback amount>");
}

// run
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
