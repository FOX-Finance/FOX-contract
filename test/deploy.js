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

let signer = { "owner": null, "oracleFeeder": null, "feeTo": null };

async function set() {
    signer.owner = await impersonateAddress("0xa29A12B879bCC89faE72687e09Da3c3995B91fe5"); // forking-net
    signer.oracleFeeder = await impersonateAddress("0x519e7e5a63a5027a9e1745ae546E77701A6fa5e7"); // forking-net
    signer.feeTo = await impersonateAddress("0x21De12f081958D5590AB70C172703345286bcDc9"); // forking-net
}

async function main() {
    await set();
}

// run
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
