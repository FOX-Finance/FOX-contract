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

async function approveCoupon() {
    let txRes;

    process.stdout.write("[Coupon] Check allowance");
    allowance = await contract.coupon.isApprovedForAll(signer.user.address, contract.foxFarm.address);
    console.log(" - complete:\t", allowance);

    if (!allowance) {
        process.stdout.write("[Coupon] Set approval for all");
        txRes = await contract.coupon.connect(signer.user).setApprovalForAll(contract.foxFarm.address, true);
        await txRes.wait();
        console.log(" - complete");

        process.stdout.write("[Coupon] Check allowance");
        allowance = await contract.coupon.isApprovedForAll(signer.user.address, contract.foxFarm.address);
        console.log(" - complete:\t", allowance);
    }
}

async function getCdp(id) {
    process.stdout.write("[FoxFarm] Get current CDP info");
    const cdp = await contract.foxFarm.cdp(id);
    console.log(" - complete:");
    console.log("\tcollateral:\t", cdp.collateral / (10 ** 18));
    console.log("\tdebt:\t\t", cdp.debt / (10 ** 18));
    console.log("\tfee:\t\t", cdp.fee / (10 ** 18));
}

async function getPdc(id) {
    process.stdout.write("[Coupon] Get current PDC info");
    const pdc = await contract.coupon.pdc(id);
    console.log(" - complete:");
    console.log("\tshare:\t\t", pdc.share / (10 ** 18));
    console.log("\tgrant:\t\t", pdc.grant / (10 ** 18));
    console.log("\tfee:\t\t", pdc.fee / (10 ** 18));
}

async function getSurplusBuybackamount() {
    process.stdout.write("[FOX] Get surplus buyback amount");
    const debtAmount = await contract.fox.surplusBuybackAmount();
    console.log(" - complete:\t", debtAmount / (10 ** 18));
}

async function getShareAmountRangeWhenBuyback(account, id) {
    process.stdout.write("[Gateway] Get shareAmountRangeWhenBuyback");
    const res = await contract.gateway.shareAmountRangeWhenBuyback(account, id);
    console.log(" - complete:");
    console.log("\tupperBound:\t", res.upperBound_ / (10 ** 18));
    console.log("\tlowerBound:\t", res.lowerBound_ / (10 ** 18));
}

async function buybackCoupon(account, shareAmount) {
    let txRes;

    process.stdout.write("[FoxFarm] Buyback Coupon");
    txRes = await contract.foxFarm.connect(signer.user).buybackCoupon(
        account, shareAmount
    );
    await txRes.wait();
    console.log(" - complete");
}

async function pairAnnihilation(cid, pid) {
    let txRes;

    process.stdout.write("[FoxFarm] Pair Annihilation");
    txRes = await contract.foxFarm.connect(signer.user).pairAnnihilation(
        cid, pid
    );
    await txRes.wait();
    console.log(" - complete");
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

    console.log("\n<Approve Coupon>");
    await approveCoupon();

    const cid = BigInt(0);

    console.log("\n<Get trust level>");
    await getTrustLevel();

    console.log("\n<Get surplus buyback amount>");
    await getSurplusBuybackamount();

    const shareAmount = BigInt(300 * (10 ** 18));

    console.log("\n<Get FOXS range>");
    await getShareAmountRangeWhenBuyback(
        signer.user.address,
        cid
    );

    // Coupon
    console.log("\n<Before: Balances>");
    await balances();

    console.log("\n<Coupon>");
    await buybackCoupon(
        signer.user.address,
        shareAmount
    );

    console.log("\n<After: Balances>");
    await balances();

    const pid = BigInt(0);

    console.log("\n<After: Get current PDC info>");
    await getPdc(pid);

    // Annihilation
    console.log("\n<Before: Get current CDP info>");
    await getCdp(cid);

    console.log("\n<Before: Get current PDC info>");
    await getPdc(pid);

    console.log("\n<Annihilation>");
    await pairAnnihilation(
        cid,
        pid
    );

    console.log("\n<Before: Get current CDP info>");
    await getCdp(cid);

    console.log("\n<Before: Get current PDC info>");
    await getPdc(pid);
}

// run
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
