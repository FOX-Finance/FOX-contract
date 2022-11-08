const { signer, contract, set, attach } = require('./set');

async function getTrustLevel() {
    process.stdout.write("[Fox] Get trust level");
    const trustLevel = await contract.fox.trustLevel();
    console.log(" - complete:\t", trustLevel / 100, "%");
}

async function approveWETH() {
    let txRes;
    let allowance;

    process.stdout.write("[WETH] Check allowance");
    allowance = await contract.weth.allowance(signer.user.address, contract.foxFarm.address);
    console.log(" - complete:\t", allowance / (10 ** 18));

    if (allowance == 0) {
        process.stdout.write("[WETH] Max approve");
        txRes = await contract.weth.connect(signer.user).approveMax(contract.foxFarm.address);
        await txRes.wait();
        console.log(" - complete");

        process.stdout.write("[WETH] Check allowance");
        allowance = await contract.weth.allowance(signer.user.address, contract.foxFarm.address);
        console.log(" - complete:\t", allowance / (10 ** 18));
    }
}

async function approveWETH2() {
    let txRes;
    let allowance;

    process.stdout.write("[WETH] Check allowance");
    allowance = await contract.weth.allowance(signer.user2.address, contract.foxFarm.address);
    console.log(" - complete:\t", allowance / (10 ** 18));

    if (allowance == 0) {
        process.stdout.write("[WETH] Max approve");
        txRes = await contract.weth.connect(signer.user2).approveMax(contract.foxFarm.address);
        await txRes.wait();
        console.log(" - complete");

        process.stdout.write("[WETH] Check allowance");
        allowance = await contract.weth.allowance(signer.user2.address, contract.foxFarm.address);
        console.log(" - complete:\t", allowance / (10 ** 18));
    }
}

async function getLtv(id) {
    process.stdout.write("[FoxFarm] Get current LTV");
    const ltv = await contract.foxFarm.currentLTV(id);
    console.log(" - complete:\t", ltv / 100, "%");

    return ltv;
}

async function getCdp(id) {
    process.stdout.write("[FoxFarm] Get current CDP info");
    const cdp = await contract.foxFarm.cdps(id);
    console.log(" - complete:");
    console.log("\tcollateral:\t", cdp.collateral / (10 ** 18));
    console.log("\tdebt:\t\t", cdp.debt / (10 ** 18));
    console.log("\tfee:\t\t", cdp.fee / (10 ** 18));
}

async function getDefaultValues(account, id) {
    process.stdout.write("[FoxFarm] Get default values");
    const res = await contract.foxFarm.defaultValuesRecollateralize(account, id);
    console.log(" - complete:");
    console.log("\tcollateral:\t", res.collateralAmount_ / (10 ** 18));
    console.log("\tltv:\t\t", res.ltv_ / 100, "%");
    console.log("\tshare:\t\t", res.shareAmount_ / (10 ** 18));
}

async function getShortfallRecollateralizeAmount() {
    process.stdout.write("[FOX] Get shortfall debt amount");
    const debtAmount = await contract.fox.shortfallRecollateralizeAmount();
    console.log(" - complete:\t", debtAmount / (10 ** 18));
}

async function getLtvRange(id, collateralAmount) {
    process.stdout.write("[FoxFarm] Get LTV range");
    const res = await contract.foxFarm.ltvRangeWhenRecollateralize(id, collateralAmount);
    console.log(" - complete:");
    console.log("\tupperBound:\t", res.upperBound_ / 100, "%");
    console.log("\tlowerBound:\t", res.lowerBound_ / 100, "%");
}

async function getCollateralAmountRangeWhenRecoll(id) {
    process.stdout.write("[FoxFarm] Get collateralAmountRangeWhenRecoll");
    const res = await contract.foxFarm.collateralAmountRangeWhenRecollateralize(id);
    console.log(" - complete:");
    console.log("\tupperBound:\t", res.upperBound_ / (10 ** 18));
    console.log("\tlowerBound:\t", res.lowerBound_ / (10 ** 18));
}

async function recollBorrowDebt(account, id, ltv) {
    let txRes;

    process.stdout.write("[FoxFarm] Recoll");
    txRes = await contract.foxFarm.connect(signer.user).recollateralizeBorrowDebtToLtv(
        account, id, ltv
    );
    await txRes.wait();
    console.log(" - complete");
}

async function getRecollAmount(id, collateralAmount, ltv) {
    process.stdout.write("[FoxFarm] Get collateral amount");
    const shareAmount = await contract.foxFarm.exchangedShareAmountFromCollateralToLtv(id, collateralAmount, ltv);
    console.log(" - complete:\t", shareAmount / (10 ** 18));

    return shareAmount;
}

async function recollDepositCollateral(account, id, collateralAmount) {
    let txRes;

    process.stdout.write("[FoxFarm] Recoll");
    txRes = await contract.foxFarm.connect(signer.user).recollateralizeDepositCollateral(
        account, id, collateralAmount
    );
    await txRes.wait();
    console.log(" - complete");
}

async function main() {
    console.log("\n<Set>");
    await set();

    console.log("\n<Attach>");
    await attach();

    console.log("\n<Approve WETH>");
    await approveWETH();

    console.log("\n<Approve WETH2>");
    await approveWETH2();

    const cid = BigInt(0);

    console.log("\nGet default values");
    await getDefaultValues(
        signer.user.address,
        cid
    );

    console.log("\n<Get trust level>");
    await getTrustLevel();

    console.log("\n<Get shortfall debt amount>");
    await getShortfallRecollateralizeAmount();

    console.log("\n<Get current LTV>");
    await getLtv(cid);

    console.log("\n<Get current CDP info>");
    await getCdp(cid);

    process.exit(1);


    // // 1. Recoll from owner
    // console.log("\n<Get LTV range>");
    // await getLtvRange(
    //     BigInt(0),
    //     BigInt(0.1 * (10 ** 18)),
    // );

    // console.log("\n<Recoll: more debt by owner>");
    // await recollBorrowDebt(
    //     signer.user.address,
    //     BigInt(0),
    //     BigInt(44 * 100)
    // );

    // console.log("\n<After: Get current LTV>");
    // ltv = await getLtv(
    //     BigInt(0)
    // );

    // console.log("\n<After: Get current CDP info>");
    // await getCdp(BigInt(0));

    // TODO: case 1
    // console.log("\n<Get recoll amount w/ different LTV>");
    // await getRecollAmount(
    //     BigInt(0),
    //     BigInt(0.3 * (10 ** 18)),
    //     BigInt(44 * 100)
    // );

    // TODO: fix
    // TODO: because of fee, only owner?
    // 2. Recoll from the other
    console.log("\nGet collateral amount range");
    await getCollateralAmountRangeWhenRecoll(
        BigInt(0)
    );

    console.log("\n<Before: Get current LTV>");
    ltv = await getLtv(
        BigInt(0)
    );

    console.log("\n<Before: Get current CDP info>");
    await getCdp(BigInt(0));

    console.log("\n<Get LTV range>");
    await getLtvRange(
        BigInt(0),
        BigInt(0.1 * (10 ** 18)),
    );

    console.log("\n<Get recoll amount>");
    await getRecollAmount(
        BigInt(0),
        BigInt(0.3 * (10 ** 18)),
        ltv
    );

    console.log("\n<Recoll: deposit collateral>");
    await recollDepositCollateral(
        signer.user.address,
        BigInt(0),
        BigInt(0.3 * (10 ** 18))
    );

    console.log("\n<After: Get current LTV>");
    await getLtv(
        BigInt(0)
    );

    console.log("\n<After: Get current CDP info>");
    await getCdp(BigInt(0));
}

// run
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
