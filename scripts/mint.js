const { signer, contract, set, attach } = require('./set');

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

async function getDefaultValues(account, id) {
    process.stdout.write("[FoxFarm] Get default values");
    const res = await contract.foxFarm.defaultValuesMint(account, id);
    console.log(" - complete:");
    console.log("\tcollateral:\t", res.collateralAmount_ / (10 ** 18));
    console.log("\tltv:\t\t", res.ltv_ / 100, "%");
    console.log("\tshare:\t\t", res.shareAmount_ / (10 ** 18));
    console.log("\tstable:\t\t", res.stableAmount_ / (10 ** 18));
}

async function getLtvRange(id, collateralAmount, shareAmount) {
    process.stdout.write("[FoxFarm] Get LTV range");
    const res = await contract.foxFarm.ltvRangeWhenMint(id, collateralAmount, shareAmount);
    console.log(" - complete:");
    console.log("\tupperBound:\t", res.upperBound_ / 100, "%");
    console.log("\tlowerBound:\t", res.lowerBound_ / 100, "%");
}

async function getCollateralAmountRange(account, id, ltv, shareAmount) {
    process.stdout.write("[FoxFarm] Get WETH range");
    const res = await contract.foxFarm.collateralAmountRangeWhenMint(account, id, ltv, shareAmount);
    console.log(" - complete:");
    console.log("\tupperBound:\t", res.upperBound_ / (10 ** 18));
    console.log("\tlowerBound:\t", res.lowerBound_ / (10 ** 18));
}

async function getShareAmountRange(account, id, collateralAmount, ltv) {
    process.stdout.write("[FoxFarm] Get FOXS range");
    const res = await contract.foxFarm.shareAmountRangeWhenMint(account, id, collateralAmount, ltv);
    console.log(" - complete:");
    console.log("\tupperBound:\t", res.upperBound_ / (10 ** 18));
    console.log("\tlowerBound:\t", res.lowerBound_ / (10 ** 18));
}

async function getRequiredFoxsAmount(collateralAmount, ltv) {
    process.stdout.write("[FoxFarm] Get required FOXS");
    const shareAmount = await contract.foxFarm.requiredShareAmountFromCollateralToLtv(
        ethers.constants.MaxUint256,
        collateralAmount,
        ltv
    );
    console.log(" - complete:\t", shareAmount / (10 ** 18));

    return shareAmount;
}

async function getRequiredWethAmount(shareAmount, ltv) {
    process.stdout.write("[FoxFarm] Get required WETH");
    const collateralAmount = await contract.foxFarm.requiredCollateralAmountFromShareToLtv(
        ethers.constants.MaxUint256,
        shareAmount,
        ltv
    );
    console.log(" - complete:\t", collateralAmount / (10 ** 18));

    return collateralAmount;
}

async function getExpectedFoxAmount(collateralAmount, shareAmount, ltv) {
    process.stdout.write("[FoxFarm] Get expected FOX");
    const stableAmount = await contract.foxFarm.expectedMintAmountToLtv(
        ethers.constants.MaxUint256,
        collateralAmount,
        ltv,
        shareAmount
    );
    console.log(" - complete:\t", stableAmount / (10 ** 18));

    return stableAmount;
}

async function mintFOX(depositAmount, stableAmount) {
    let txRes;

    process.stdout.write("[FoxFarm] Mint FOX");
    txRes = await contract.foxFarm.connect(signer.user).openAndDepositAndBorrow(
        depositAmount,
        stableAmount
    );
    await txRes.wait();

    const id = await contract.foxFarm.id();
    console.log(" - complete:\t", id);
}

async function main() {
    console.log("\n<Set>");
    await set();

    console.log("\n<Attach>");
    await attach();

    console.log("\n<Approve WETH>");
    await approveWETH();

    console.log("\n<Approve FOXS>");
    await approveFOXS();

    const cid = BigInt(0);

    console.log("\nGet default values");
    await getDefaultValues(
        signer.user.address,
        cid
    );

    const collateralAmount = BigInt(1000 * (10 ** 18));
    const shareAmount = BigInt(800 * (10 ** 18));
    const ltv = BigInt(40 * 100);

    console.log("\n<Get LTV range>");
    await getLtvRange(
        cid,
        collateralAmount,
        shareAmount
    );

    console.log("\n<Get WETH range>");
    await getCollateralAmountRange(
        signer.user.address,
        cid,
        ltv,
        shareAmount
    );

    console.log("\n<Get FOXS range>");
    await getShareAmountRange(
        signer.user.address,
        cid,
        collateralAmount,
        ltv
    );

    // Case 1: Input WETH & LTV
    console.log("\n<Get required FOXS amount>");
    const requiredShareAmount = await getRequiredFoxsAmount(collateralAmount, ltv);

    // Case 2: Input FOXS
    console.log("\n<Get required WETH amount>");
    const requiredCollateralAmount = await getRequiredWethAmount(shareAmount, ltv);

    console.log("\n<Compare results>");
    const expectedStableAmount1 = await getExpectedFoxAmount(collateralAmount, requiredShareAmount, ltv);
    const expectedStableAmount2 = await getExpectedFoxAmount(requiredCollateralAmount, shareAmount, ltv);
    const expectedStableAmount3 = await getExpectedFoxAmount(collateralAmount, shareAmount, ltv);

    console.log("\n<Before: Balances>");
    await balances();

    console.log("\n<Mint FOX>");
    await mintFOX(collateralAmount, expectedStableAmount1);

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
