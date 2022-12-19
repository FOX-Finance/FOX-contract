const { signer, contract, set, attach } = require('./set');

async function balances() {
    let balance;

    process.stdout.write("[WETH] Check balance");
    balance = await contract.weth.balanceOf(signer.user.address);
    console.log(" - complete:\t", balance / (10 ** 18));

    process.stdout.write("[FOXS] Check balance");
    balance = await contract.foxs.balanceOf(signer.user.address);
    console.log(" - complete:\t", balance / (10 ** 18));

    process.stdout.write("[FOX] Check balance");
    balance = await contract.fox.balanceOf(signer.user.address);
    console.log(" - complete:\t\t", balance / (10 ** 18));
}

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

async function getLtv(id) {
    process.stdout.write("[FoxFarm] Get current LTV");
    const ltv = await contract.foxFarm.currentLTV(id);
    console.log(" - complete:\t", ltv / 100, "%");

    return ltv;
}

async function getCdp(id) {
    process.stdout.write("[FoxFarm] Get current CDP info");
    const cdp = await contract.foxFarm.cdp(id);
    console.log(" - complete:");
    console.log("\tcollateral:\t", cdp.collateral / (10 ** 18));
    console.log("\tdebt:\t\t", cdp.debt / (10 ** 18));
    console.log("\tfee:\t\t", cdp.fee / (10 ** 18));
}

async function getDefaultValues(account, id) {
    process.stdout.write("[Gateway] Get default values");
    const res = await contract.gateway.defaultValuesRecollateralize(account, id);
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
    process.stdout.write("[Gateway] Get LTV range");
    const res = await contract.gateway.ltvRangeWhenRecollateralize(id, collateralAmount);
    console.log(" - complete:");
    console.log("\tupperBound:\t", res.upperBound_ / 100, "%");
    console.log("\tlowerBound:\t", res.lowerBound_ / 100, "%");
}

async function getCollateralAmountRangeWhenRecoll(account, id, ltv) {
    process.stdout.write("[Gateway] Get collateralAmountRangeWhenRecoll");
    const res = await contract.gateway.collateralAmountRangeWhenRecollateralize(account, id, ltv);
    console.log(" - complete:");
    console.log("\tupperBound:\t", res.upperBound_ / (10 ** 18));
    console.log("\tlowerBound:\t", res.lowerBound_ / (10 ** 18));
}

async function getRecollAmount(id, collateralAmount, ltv) {
    process.stdout.write("[Gateway] Get share amount");
    const shareAmount = await contract.gateway.exchangedShareAmountFromCollateralToLtv(id, collateralAmount, ltv);
    console.log(" - complete:\t", shareAmount / (10 ** 18));

    return shareAmount;
}

async function recoll(account, id, collateralAmount, ltv) {
    let txRes;

    process.stdout.write("[FoxFarm] Recoll");
    txRes = await contract.foxFarm.connect(signer.user).recollateralize(
        account, id, collateralAmount, ltv
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

    const collateralAmount = BigInt(1000 * (10 ** 18));
    const ltv = BigInt(21 * 100);

    console.log("\n<Get LTV range>");
    await getLtvRange(
        cid,
        collateralAmount,
    );

    console.log("\n<Get collateral amount range>");
    await getCollateralAmountRangeWhenRecoll(
        signer.user.address,
        cid,
        ltv
    );

    // Recoll
    console.log("\n<Expected recoll amount>");
    await getRecollAmount(
        cid,
        collateralAmount,
        ltv
    );

    console.log("\n<Before: Get current LTV>");
    await getLtv(cid);

    console.log("\n<Before: Get current CDP info>");
    await getCdp(cid);

    console.log("\n<Before: Balances>");
    await balances();

    console.log("\n<Recoll: more debt by owner>");
    await recoll(
        signer.user.address,
        cid,
        collateralAmount,
        ltv
    );

    console.log("\n<After: Get current LTV>");
    await getLtv(cid);

    console.log("\n<After: Get current CDP info>");
    await getCdp(cid);

    console.log("\n<After: Balances>");
    await balances();
}

// run
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
