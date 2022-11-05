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

async function getRequiredFoxsAmount(collateralAmount, ltv) {
    process.stdout.write("[FoxFarm] Get required FOXS");
    const shareAmount = await contract.foxFarm.requiredShareAmountFromCollateralWithLtv(
        ethers.constants.MaxUint256,
        collateralAmount,
        ltv
    );
    console.log(" - complete:\t", shareAmount / (10 ** 18));

    return shareAmount;
}

async function getRequiredWethAmount(shareAmount, ltv) {
    process.stdout.write("[FoxFarm] Get required WETH");
    const collateralAmount = await contract.foxFarm.requiredCollateralAmountFromShareWithLtv(
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

    console.log("\n<Before: Balances>");
    await balances();

    // Case 1: Input WETH & LTV
    const collateralAmount = BigInt(0.01 * (10 ** 18));
    const ltv = BigInt(40 * 100);
    console.log("\n<Get required FOXS amount>");
    const shareAmount = await getRequiredFoxsAmount(collateralAmount, ltv);

    // Case 2: Input FOXS
    console.log("\n<Get required WETH amount>");
    const requiredCollateralAmount = await getRequiredWethAmount(shareAmount, ltv);

    // TODO: requiredCollateralAmount == collateralAmount, but...
    console.log("\n<TODO: Mitigate floating error>");
    const expectedStableAmount1 = await getExpectedFoxAmount(collateralAmount, shareAmount, ltv);
    const expectedStableAmount2 = await getExpectedFoxAmount(requiredCollateralAmount, shareAmount, ltv);

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
