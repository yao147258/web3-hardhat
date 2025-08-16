const {ethers} = require('hardhat')

async function main() {
    // 1. create factory contract
    const factory = await ethers.getContractFactory('FundMe')
    console.log(`FundMe contract deploying...`)

    // 2. deploy factory contract
    const fundMe = await factory.deploy(180)
    await fundMe.waitForDeployment()

    // 3.
    console.log(`FundMe contract deploy successfully, contract address is ${fundMe.target}`)
}

main().then().catch((error) => {
    console.error(error)

    process.exit(0)
})


