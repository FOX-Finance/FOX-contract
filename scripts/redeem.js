const { signer, contract, set, attach } = require('./set');

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

async function getCdp(id) {
    process.stdout.write("[FoxFarm] Get current CDP info");
    const cdp = await contract.foxFarm.cdps(id);
    console.log(" - complete:");
    console.log("\tcollateral:\t", cdp.collateral / (10 ** 18));
    console.log("\tdebt:\t\t", cdp.debt / (10 ** 18));
    console.log("\tfee:\t\t", cdp.fee / (10 ** 18));
}

async function getLtv(id) {
    process.stdout.write("[FoxFarm] Get current LTV");
    const ltv = await contract.foxFarm.currentLTV(id);
    console.log(" - complete:\t", ltv / 100, "%");

    return ltv;
}

async function getLtvRange(id, stableAmount) {
    process.stdout.write("[FoxFarm] Get LTV range");
    const res = await contract.foxFarm.ltvRangeWhenRedeem(id, stableAmount);
    console.log(" - complete:");
    console.log("\tupperBound:\t", res.upperBound_ / 100, "%");
    console.log("\tlowerBound:\t", res.lowerBound_ / 100, "%");
}

async function getExpectedRedeemAmount(id, stableAmount, ltv) {
    process.stdout.write("[FoxFarm] Get expected redeem amount");
    const res = await contract.foxFarm.expectedRedeemAmountToLtv(
        id,
        stableAmount,
        ltv
    );
    console.log(" - complete:");
    console.log("\tcollateralAmount:\t", res.emittedCollateralAmount_ / (10 ** 18));
    console.log("\tshareAmount:\t\t", res.emittedShareAmount_ / (10 ** 18));

    return { 'collateralAmount': res.emittedCollateralAmount_, 'shareAmount': res.emittedShareAmount_ };
}

async function redeemFOX(id, repayAmount, withdrawAmount) {
    let txRes;

    process.stdout.write("[FoxFarm] Redeem FOX");
    txRes = await contract.foxFarm.connect(signer.user).repayAndWithdraw(
        id,
        repayAmount,
        withdrawAmount
    );
    await txRes.wait();
    console.log(" - complete");
}

async function main() {
    console.log("\n<Set>");
    await set();

    console.log("\n<Attach>");
    await attach();

    console.log("\n<Approve FOX>");
    await approveFOX();

    console.log("\n<Before: Balances>");
    await balances();

    console.log("\n<Get current LTV>");
    const ltv = await getLtv(BigInt(0));

    console.log("\n<Get current CDP info>");
    await getCdp(BigInt(0));

    console.log("\n<Get LTV range>");
    await getLtvRange(
        BigInt(0),
        BigInt(4 * (10 ** 18)),
    );

    console.log("\n<Expected redeem amount>");
    const res = await getExpectedRedeemAmount(
        BigInt(0),
        BigInt(4 * (10 ** 18)),
        BigInt(14.2 * 100)
    );
    const redeemCollateralAmount = res.collateralAmount;

    console.log("\n<Redeem FOX>");
    await redeemFOX(
        BigInt(0), // id
        BigInt(4 * (10 ** 18)), // repayAmount
        BigInt(redeemCollateralAmount) // withdrawAmount
    );

    console.log("\n<After: Balances>");
    await balances();

    console.log("\n<Get current LTV>");
    await getLtv(BigInt(0));

    console.log("\n<Get current CDP info>");
    await getCdp(BigInt(0));
}

// run
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
