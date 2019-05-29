const HDWalletProvider = require("truffle-hdwallet-provider");
var mnemonic = "mobile occur used fine audit online tent ethics shine enact conduct memory";




module.exports = {
  // Uncommenting the defaults below
  // provides for an easier quick-start with Ganache.
  // You can also follow this format for other networks;
  // see <http://truffleframework.com/docs/advanced/configuration>
  // for more details on how to specify configuration options!

  networks: {
    development: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "*"
    },
    test: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "*"
    },
    kovan_infura: {
      provider: () => new HDWalletProvider(mnemonic, "https://kovan.infura.io/a742fdcf0d85454ba43aa0169a2a9877"),
      network_id: 42,
      gas: 470000
    },
    ropsten_infura: {
      provider: () => new HDWalletProvider(mnemonic, "https://ropsten.infura.io/a742fdcf0d85454ba43aa0169a2a9877"),
      network_id: 3,
      gas: 4700000
    },

    ropsten: {
      host: "127.0.0.1",
      port: 8545,
      network_id: 3,
      gas: 470000
    },

  },
  mocha: {
    enableTimeouts: false
  }
};
