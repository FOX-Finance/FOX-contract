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

async function approveFOX() {
    let txRes;
    let allowance;

    process.stdout.write("[FOX] Check allowance");
    allowance = await contract.fox.allowance(signer.user.address, contract.foxFarm.address);
    console.log(" - complete:\t", allowance / (10 ** 18));

    if (allowance == 0) {
        process.stdout.write("[FOX] Max approve");
        txRes = await contract.fox.connect(signer.user).approveMax(contract.foxFarm.address);
        await txRes.wait();
        console.log(" - complete");

        process.stdout.write("[FOX] Check allowance");
        allowance = await contract.fox.allowance(signer.user.address, contract.foxFarm.address);
        console.log(" - complete:\t", allowance / (10 ** 18));
    }
}

async function approveFOXS2() {
    let txRes;
    let allowance;

    process.stdout.write("[FOXS] Check allowance");
    allowance = await contract.foxs.allowance(signer.user2.address, contract.foxFarm.address);
    console.log(" - complete:\t", allowance / (10 ** 18));

    if (allowance == 0) {
        process.stdout.write("[FOXS] Max approve");
        txRes = await contract.foxs.connect(signer.user2).approveMax(contract.foxFarm.address);
        await txRes.wait();
        console.log(" - complete");

        process.stdout.write("[FOXS] Check allowance");
        allowance = await contract.foxs.allowance(signer.user2.address, contract.foxFarm.address);
        console.log(" - complete:\t", allowance / (10 ** 18));
    }
}

async function approveFOX2() {
    let txRes;
    let allowance;

    process.stdout.write("[FOX] Check allowance");
    allowance = await contract.fox.allowance(signer.user2.address, contract.foxFarm.address);
    console.log(" - complete:\t", allowance / (10 ** 18));

    if (allowance == 0) {
        process.stdout.write("[FOX] Max approve");
        txRes = await contract.fox.connect(signer.user2).approveMax(contract.foxFarm.address);
        await txRes.wait();
        console.log(" - complete");

        process.stdout.write("[FOX] Check allowance");
        allowance = await contract.fox.allowance(signer.user2.address, contract.foxFarm.address);
        console.log(" - complete:\t", allowance / (10 ** 18));
    }
}

async function getLtv(id) {
    process.stdout.write("[FoxFarm] Get current LTV");
    const ltv = await contract.foxFarm.currentLTV(id);
    console.log(" - complete:\t", ltv / 100, "%");

    return ltv;
}

async function getDefaultValues(account, id) {
    process.stdout.write("[Gateway] Get default values");
    const res = await contract.gateway.defaultValuesBuyback(account, id);
    console.log(" - complete:");
    console.log("\tshare:\t\t", res.shareAmount_ / (10 ** 18));
    console.log("\tcollateral:\t", res.collateralAmount_ / (10 ** 18));
    console.log("\tltv:\t\t", res.ltv_ / 100, "%");
}

async function getBuybackAmount(id, shareAmount, ltv) {
    process.stdout.write("[Gateway] Get collateral amount");
    const collateralAmount = await contract.gateway.exchangedCollateralAmountFromShareToLtv(id, shareAmount, ltv);
    console.log(" - complete:\t", collateralAmount / (10 ** 18));

    return collateralAmount;
}

async function getLtvRange(id, stableAmount) {
    process.stdout.write("[Gateway] Get LTV range");
    const res = await contract.gateway.ltvRangeWhenBuyback(id, stableAmount);
    console.log(" - complete:");
    console.log("\tupperBound:\t", res.upperBound_ / 100, "%");
    console.log("\tlowerBound:\t", res.lowerBound_ / 100, "%");
}

async function getCdp(id) {
    process.stdout.write("[FoxFarm] Get current CDP info");
    const cdp = await contract.foxFarm.cdp(id);
    console.log(" - complete:");
    console.log("\tcollateral:\t", cdp.collateral / (10 ** 18));
    console.log("\tdebt:\t\t", cdp.debt / (10 ** 18));
    console.log("\tfee:\t\t", cdp.fee / (10 ** 18));
}

async function buybackRepayDebt(id, shareAmount) {
    let txRes;

    process.stdout.write("[FoxFarm] Buyback");
    txRes = await contract.foxFarm.connect(signer.user2).buybackRepayDebt(
        id, shareAmount
    );
    await txRes.wait();
    console.log(" - complete");
}

async function buybackWithdrawCollateral(account, id, shareAmount, ltv) {
    let txRes;

    process.stdout.write("[FoxFarm] Buyback");
    txRes = await contract.foxFarm.connect(signer.user).buybackWithdrawCollateral(
        account, id, shareAmount, ltv
    );
    await txRes.wait();
    console.log(" - complete");
}

async function getSurplusBuybackamount() {
    process.stdout.write("[FOX] Get surplus buyback amount");
    const debtAmount = await contract.fox.surplusBuybackAmount();
    console.log(" - complete:\t", debtAmount / (10 ** 18));
}

async function main() {
    console.log("\n<Set>");
    await set();

    console.log("\n<Attach>");
    await attach();

    console.log("\n<Approve FOXS>");
    await approveFOXS();

    console.log("\n<Approve FOX>");
    await approveFOX();

    console.log("\n<Approve FOXS2>");
    await approveFOXS2();

    console.log("\n<Approve FOX2>");
    await approveFOX2();

    const cid = BigInt(0);

    console.log("\nGet default values from owner");
    await getDefaultValues(
        signer.user.address,
        cid
    );

    console.log("\nGet default values from other");
    await getDefaultValues(
        signer.user2.address,
        cid
    );

    console.log("\n<Get trust level>");
    await getTrustLevel();

    console.log("\n<Get surplus buyback amount>");
    await getSurplusBuybackamount();

    console.log("\n<Get current LTV>");
    await getLtv(cid);

    console.log("\n<Get current CDP info>");
    await getCdp(cid);

    process.exit(1);

    // 1. Buyback from other user
    console.log("\n<Get LTV range>");
    await getLtvRange(
        BigInt(0),
        BigInt(0.1 * (10 ** 18)),
    );

    console.log("\n<Buyback: repay debt from other user>");
    await buybackRepayDebt(
        BigInt(0),
        BigInt(0.1 * (10 ** 18))
    );

    console.log("\n<After: Get current LTV>");
    ltv = await getLtv(
        BigInt(0)
    );

    console.log("\n<After: Get current CDP info>");
    await getCdp(BigInt(0));

    // // 2. Buyback from owner
    // console.log("\n<Before: Get current LTV>");
    // ltv = await getLtv(
    //     BigInt(0)
    // );

    // console.log("\n<Before: Get current CDP info>");
    // await getCdp(BigInt(0));

    // console.log("\n<Get LTV range>");
    // await getLtvRange(
    //     BigInt(0),
    //     BigInt(0.3 * (10 ** 18)),
    // );

    // console.log("\n<Get buyback amount>");
    // const collateralAmount = await getBuybackAmount(
    //     BigInt(0),
    //     BigInt(0.3 * (10 ** 18)),
    //     ltv
    // );

    // console.log("\n<Get buyback amount w/ different LTV>");
    // const collateralAmountWithLtv = await getBuybackAmount(
    //     BigInt(0),
    //     BigInt(0.3 * (10 ** 18)),
    //     BigInt(38 * 100)
    // );

    // console.log("\n<Buyback: repay debt from owner>");
    // await buybackWithdrawCollateral(
    //     signer.user.address,
    //     BigInt(0),
    //     BigInt(0.3 * (10 ** 18)),
    //     BigInt(38 * 100)
    // );

    // console.log("\n<After: Get current LTV>");
    // await getLtv(
    //     BigInt(0)
    // );

    // console.log("\n<After: Get current CDP info>");
    // await getCdp(BigInt(0));
}

// run
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
