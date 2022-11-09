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
    const cdp = await contract.foxFarm.cdp(id);
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

async function getDefaultValues(account, id) {
    process.stdout.write("[Gateway] Get default values");
    const res = await contract.gateway.defaultValueRedeem(account, id);
    console.log(" - complete:");
    console.log("\tstable:\t\t", res.stableAmount_ / (10 ** 18));
    console.log("\tcollateral:\t", res.collateralAmount_ / (10 ** 18));
    console.log("\tltv:\t\t", res.ltv_ / 100, "%");
    console.log("\tshare:\t\t", res.shareAmount_ / (10 ** 18));
}

async function getLtvRange(id, stableAmount) {
    process.stdout.write("[Gateway] Get LTV range");
    const res = await contract.gateway.ltvRangeWhenRedeem(id, stableAmount);
    console.log(" - complete:");
    console.log("\tupperBound:\t", res.upperBound_ / 100, "%");
    console.log("\tlowerBound:\t", res.lowerBound_ / 100, "%");
}

async function getFoxRange(account, id) {
    process.stdout.write("[Gateway] Get FOX range");
    const res = await contract.gateway.stableAmountRangeWhenRedeem(account, id);
    console.log(" - complete:");
    console.log("\tupperBound:\t", res.upperBound_ / (10 ** 18));
    console.log("\tlowerBound:\t", res.lowerBound_ / (10 ** 18));
}

async function getExpectedRedeemAmount(id, stableAmount, ltv) {
    process.stdout.write("[Gateway] Get expected redeem amount");
    const res = await contract.gateway.expectedRedeemAmountToLtv(
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

    const cid = BigInt(0);

    console.log("\nGet default values");
    await getDefaultValues(
        signer.user.address,
        cid
    );

    console.log("\n<Get current LTV>");
    await getLtv(cid);

    console.log("\n<Get current CDP info>");
    await getCdp(cid);

    const stableAmount = BigInt(1000 * (10 ** 18));
    const ltv = BigInt(50 * 100);

    console.log("\n<Get LTV range>");
    await getLtvRange(
        cid,
        stableAmount,
    );

    console.log("\n<Get FOX range>");
    await getFoxRange(
        signer.user.address,
        cid
    );

    // Input FOX
    console.log("\n<Expected redeem amount>");
    const res = await getExpectedRedeemAmount(
        cid,
        stableAmount,
        ltv
    );
    const redeemCollateralAmount = res.collateralAmount;

    console.log("\n<Before: Balances>");
    await balances();

    console.log("\n<Redeem FOX>");
    await redeemFOX(
        cid,
        stableAmount, // repayAmount
        BigInt(redeemCollateralAmount) // withdrawAmount
    );

    console.log("\n<After: Balances>");
    await balances();

    console.log("\n<Get current LTV>");
    await getLtv(cid);

    console.log("\n<Get current CDP info>");
    await getCdp(cid);
}

// run
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
