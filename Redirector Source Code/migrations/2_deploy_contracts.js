const REDIRECTOR = artifacts.require("Redirector")
const SOURCE = artifacts.require("SmartChefInitializable")
const DRAIN = artifacts.require("SimpleAggregator")
const SHARE = artifacts.require("ShareToken")

module.exports = async function(deployer, network, accounts) {
  
  await deployer.deploy(SOURCE)
  const source = await SOURCE.deployed()

  await deployer.deploy(SHARE, "mooRampBUSDLP", "mooRB")
  const share = await SHARE.deployed()

  await deployer.deploy(DRAIN,"0x8519EA49c997f50cefFa444d240fB655e89248Aa", share.address)
  const drain = await DRAIN.deployed()

  await deployer.deploy(REDIRECTOR, share.address, drain.address, source.address)
};
