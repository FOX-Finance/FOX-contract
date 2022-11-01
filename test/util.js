// use any address
// Example:
// const sender = await impersonateAddress("0x3dC0aBd0e5C5de73C839EF6b9697694F95121233");
const impersonateAddress = async (address) => {
    await hre.network.provider.request({
        method: 'hardhat_impersonateAccount',
        params: [address],
    });
    const signer = await ethers.provider.getSigner(address);
    signer.address = signer._address;
    return signer;
};
