var Lovecoincore = artifacts.require("./Lovecoincore.sol");

module.exports = function(deployer) {
  deployer.deploy(Lovecoincore);
};
