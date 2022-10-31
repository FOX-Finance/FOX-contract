// use any address
const impersonateAddress = async (address) => {
    await hre.network.provider.request({
        method: 'hardhat_impersonateAccount',
        params: [address],
    });
    const signer = await ethers.provider.getSigner(address);
    signer.address = signer._address;
    return signer;
};

let owner, oracleFeeder, feeTo;

async function init() {
    [owner, oracleFeeder, feeTo] = await ethers.getSigners(); // main/test-net
    // owner = await impersonateAddress("0xa29A12B879bCC89faE72687e09Da3c3995B91fe5"); // forking-net
    // oracleFeeder = await impersonateAddress("0x519e7e5a63a5027a9e1745ae546E77701A6fa5e7"); // forking-net
    // feeTo = await impersonateAddress("0x21De12f081958D5590AB70C172703345286bcDc9"); // forking-net

    let balanceOfOwner = await owner.getBalance();
    console.log("Deployer:\t", owner.address, `(${balanceOfOwner})`);
    console.log("OracleFeeder:\t", oracleFeeder.address);
    console.log("FeeTo:\t\t", feeTo.address);
}

let txRes;

async function main() {
    process.stdout.write("Attach");
    const fox = await ethers.getContractAt("FOX", "0x9888286f334085819441563BC0F2bE8932E878e7");
    console.log(" complete");

    // process.stdout.write("Add allowlist");
    // txRes = await fox.connect(owner).addAllowlist(oracleFeeder.address);
    // await txRes.wait();
    // console.log(" complete");

    // process.stdout.write("Update FOX price");
    // txRes = await fox.connect(oracleFeeder).updateStablePrice(BigInt(10001), BigInt(0));
    // await txRes.wait();
    // console.log(":\t", await fox.connect(oracleFeeder).getStablePrice());

    process.stdout.write("Update trust level");
    txRes = await fox.connect(owner).updateTrustLevel();
    await txRes.wait();
    console.log(":\t", await fox.trustLevel());
}

// run
init().then(() => {
    main()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
});
