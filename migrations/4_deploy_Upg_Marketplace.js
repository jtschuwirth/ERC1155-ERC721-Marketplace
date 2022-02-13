const { deployProxy } = require('@openzeppelin/truffle-upgrades');

const Marketplace = artifacts.require("Marketplace");

module.exports = async function (deployer) {
  await deployProxy(Marketplace, { deployer, initializer: "initialize" });
};